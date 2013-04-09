from django import forms
from django.shortcuts import render
from django.http import HttpResponse, HttpResponseRedirect
from django.template import Context, loader
from django.shortcuts import render_to_response
from django.core.urlresolvers import reverse
from django.conf import settings

import zipfile
import os.path
import dicom as pydicom
from dicom_web.models import Dicom, Patient, Study, Series, Image
import subprocess

from PIL import Image as PIL_Image

class UploadFileForm(forms.Form):
    filedata = forms.FileField()

def index(request):
    upload_file_form = UploadFileForm()
    context = {
        'form': upload_file_form,
        'dicom_list': Dicom.objects.all(),
    }
    return render(request, "dicom_web/index.html", context)

def upload(request):
    if request.method == 'POST':
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            filedata = form.cleaned_data['filedata']
            resp = handle_uploaded_file(filedata)
            return HttpResponseRedirect(reverse("dicom:index"))
    return HttpResponse("fail")

def view_dicom(request):
    dicomdir = request.GET["dicom"]
    dicom = Dicom.objects.filter(base_dir = dicomdir)[0]
    patient = Patient.objects.get(dicom = dicom)
    study = Study.objects.get(patient = patient)
    series = Series.objects.filter(study = study)
    context = {
        'patient': patient,
        'study:': study,
        'series_list': series
    }
    return render(request, "dicom_web/view_dicom.html", context)

def view_series(request):

    choice = request.GET["series"]

    series = Series.objects.filter(description = choice)[0]
    study = series.study
    patient = study.patient
    dicom = patient.dicom

    base_dir = dicom.base_dir

    images = Image.objects.filter(series = series).order_by("instanceNumber")

    image = images[0]
    fileID = image.fileID
    fileID = fileID.replace(" ","")
    fileID = fileID.replace("'","")
    fileID = fileID.replace("[","")
    fileID = fileID.replace("]","")
    fileID = fileID.split(',')
    imageDir = os.path.join(settings.MEDIA_ROOT, base_dir, *fileID)
    if (os.path.exists(imageDir + ".jpg") == False):
            extract_image(imageDir)
    imageUrl = os.path.join(settings.MEDIA_URL, base_dir, *fileID) + ".jpg"

    context = {
        'image': imageUrl,
    }

    return render(request, "dicom_web/view_series.html", context)

def view_slide(request):
    return

def handle_uploaded_file(f):
    datadir = "media"
    filepath = os.path.join(datadir, f.name)
    basename = os.path.splitext(os.path.basename(f.name))[0]
    # Write data to server
    with open(filepath, 'wb+') as destination:
        for chunk in f.chunks():
            destination.write(chunk)
    # Unzip file
    zf = zipfile.ZipFile(filepath)
    zf.extractall(datadir)
    unzipdirectory = os.path.join(datadir, basename)
    # Read DICOM into database
    return process_dicom(unzipdirectory)

def extract_image(pathIn):
    dcmdjpeg = os.path.join("C:","\dcmtk-bin","dcmjpeg","apps","Debug","dcmdjpeg.exe")
    pathOut = pathIn + "_temp"
    subprocess.call([dcmdjpeg, pathIn, pathOut])
    # Now get your image data
    dcm = pydicom.read_file(pathOut)
    # Scale image data to uint8
    imageData = dcm.pixel_array#*float(255)/65535
    # Convert image data to image file
    im = PIL_Image.fromarray(imageData, "L")
    im.save(pathIn+".tiff")
    im = PIL_Image.open(pathIn+".tiff")
    im.save(pathIn+".jpg")
    os.remove(pathOut)
    #os.remove(pathIn+".tiff")


def process_dicom(d):
    dicomdirPath = os.path.join(d, "DICOMDIR")
    ds = pydicom.read_file(dicomdirPath)

    dicom = {}
    dicom['series'] = {}

    # Parse DICOMDIR

    currentSeries = 0
    for record in ds.DirectoryRecordSequence:
        #print record
        #raw_input()
       
        if record.DirectoryRecordType == 'PATIENT':
            patient = {}
            patient['id'] = record.PatientID
            patient['name'] = record.PatientName
            patient['birthdate'] = record.PatientBirthDate
            patient['sex'] = record.PatientSex
            dicom['patient'] = patient
            
        if record.DirectoryRecordType == 'STUDY':
            study = {}
            study['date'] = record.StudyDate
            study['time'] = record.StudyTime
            study['accessionNumber'] = record.AccessionNumber
            study['description'] = record.StudyDescription
            study['instanceUID'] = record.StudyInstanceUID
            study['id'] = record.StudyID
            dicom['study'] = study
        
        if record.DirectoryRecordType == 'SERIES':
            series = {}
            series['date'] = record.SeriesDate
            series['time'] = record.SeriesTime
            series['modality'] = record.Modality
            series['institutionName'] = record.InstitutionName
            series['institutionAddress'] = record.InstitutionAddress
            series['description'] = record.SeriesDescription
            series['instanceUID'] = record.SeriesInstanceUID
            series['number'] = record.SeriesNumber
            
            currentSeries = int(record.SeriesNumber)
            dicom['series'][currentSeries] = {}
            dicom['series'][currentSeries]['meta'] = series
            dicom['series'][currentSeries]['images'] = {}
         
        if record.DirectoryRecordType == 'IMAGE':
            image = {}
            image['fileID'] = record.ReferencedFileID
            image['pixelSpacing'] = record.PixelSpacing
            image['rows'] = record.Rows
            image['columns'] = record.Columns
            image['instanceNumber'] = record.InstanceNumber
            image['contentDate'] = record.ContentDate
            image['contentTime'] = record.ContentTime
            image['imagePosition'] = record.ImagePositionPatient
            image['imageOrientation'] = record.ImageOrientationPatient
            
            imageNumber = int(record.InstanceNumber)
            dicom['series'][currentSeries]['images'][imageNumber] = image      

    dicomModel = Dicom.objects.create(base_dir = os.path.split(d)[-1])
    patientModel = Patient.objects.create(dicom = dicomModel, 
        patientId = dicom['patient']['id'],
        name = dicom['patient']['name'],
        birthdate = dicom['patient']['birthdate'],
        sex = dicom['patient']['sex'],
        )
    studyModel = Study.objects.create(patient = patientModel,
        studyId = dicom['study']['id'],
        date = dicom['study']['date'],
        time = dicom['study']['time'],
        accessionNumber = dicom['study']['accessionNumber'],
        description = dicom['study']['description'],
        instanceUID = dicom['study']['instanceUID'],
        )
    for key, series in dicom['series'].iteritems():
        seriesModel = Series.objects.create(study = studyModel,
            date = series['meta']['date'],
            time = series['meta']['time'],
            modality = series['meta']['modality'],
            institutionName = series['meta']['institutionName'],
            institutionAddress = series['meta']['institutionAddress'],
            description = series['meta']['description'],
            instanceUID = series['meta']['instanceUID'],
            number = series['meta']['number'],
        )
        for key, image in series['images'].iteritems():
            imageModel = Image.objects.create(series = seriesModel,
            fileID = image['fileID'],
            pixelSpacing = image['pixelSpacing'],
            rows = image['rows'],
            columns = image['columns'],
            instanceNumber = image['instanceNumber'],
            contentDate = image['contentDate'],
            contentTime = image['contentTime'],
            imagePosition =  image['imagePosition'],
            imageOrientation = image['imageOrientation'],
        )
    patientName = dicom['patient']['name']
    return patientName