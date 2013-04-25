import dicom as pydicom
import errno
import os
import subprocess
import matplotlib.pyplot as pyplot
import time
from PIL import Image
import numpy

pyplot.ion()

print "running load.py \n"

# dcmdjpeg options dcmfile-in dcmfile-out
# TO-DO: Change to relative path.
dcmdjpeg = os.path.join("C:","\dcmtk-bin","dcmjpeg","apps","Debug","dcmdjpeg.exe")

patient = "Juan_Cantelejo"
# dataDir is the project "data" directory.
# TO-DO: Change to relative path.

dataDir = os.path.join("C:","\Users","Nick","Dropbox","Nick Wong Thesis","Software","data")
patientDir = os.path.join(dataDir,"input",patient)

def extract_image(pathIn):
    dcmdjpeg = os.path.join("C:","\dcmtk-bin","dcmjpeg","apps","Debug","dcmdjpeg.exe")
    pathOut = pathIn + "_temp"
    subprocess.call([dcmdjpeg, pathIn, pathOut])
    # Now get your image data
    dcm = pydicom.read_file(pathOut)
    # Scale image data to uint8
    imageData[number] = dcm.pixel_array*float(255)/65535
    # Convert image data to image file
    im = Image.fromarray(imageData[number])
    im.save(pathIn+".tiff","tiff")
    os.remove(pathOut)

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

dirOut = os.path.join(dataDir, "output", "decompressed")

dicom_data = list()

dicomDir = os.path.join(patientDir, "DICOMDIR")
ds = pydicom.read_file(dicomDir)


#==============================================================================
# 
# Organization
# dicom: {
#     patient: {
#         id: 
#         name:
#         ...
#     }
#     study: {
#         date:
#         time:
#         ...
#     }
#     series: {
#        seriesNumber: { 
#             metadata: {
#                 date:
#                 time:
#                 ...
#             }
#             imageNumber: {
#                 image_0: {
#                     fileID:
#                     rows:
#                     ...
#                 }
#         
#            }
#        }
#        ...
#    }
# }
#==============================================================================

dicom = {}
dicom['series'] = {}

# Parse DICOMDIR
print "Reading DICOMDIR... \n"

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

# Print patient and study information:
patientName = dicom['patient']['name']
studyDescription = dicom['study']['description']
print "Patient name:\t{0}".format(patientName)
print "Study description:\t{0}".format(studyDescription)       
print ""
       
# Select series prompt
print "Select series to process:"
for key, series in dicom['series'].iteritems():
    number = series['meta']['number']
    description = series['meta']['description']
    imageCount = len(series['images'])
    print "{0}:\t{1}\t\tImages:{2}".format(number, description, imageCount)    
print ">>>",
selectedSeries = int(raw_input())
# TO-DO check valid selection
number = dicom['series'][selectedSeries]['meta']['number']
description = dicom['series'][selectedSeries]['meta']['description']
imageCount = len(dicom['series'][selectedSeries]['images'])
print "Selected: "
print "{0}:\t{1}\t\tImages:{2}".format(number, description, imageCount)    
print ""

# Process series
print "Processing series..."
imageData = {}
for key, images in dicom['series'][selectedSeries]['images'].iteritems():
    fileID = images['fileID']
    number = images['instanceNumber']
    # Extract the relative path to the DICOM file
    pathIn = os.path.join(patientDir, *fileID)
    extract_image(pathIn)

    if 1:
        # Save and decompress JPEG files
        make_sure_path_exists(os.path.join(dataDir, "output", "decompressed", *fileID[0:-1]))
        pathOut = os.path.join(dataDir, "output", "decompressed", *fileID)
        subprocess.call([dcmdjpeg, pathIn, pathOut])
        # Now get your image data
        dcm = pydicom.read_file(pathOut)
        imageData[number] = dcm.pixel_array.astype(numpy.uint32)
        #imageData[number] = (dcm.pixel_array.astype(float)*float(255)/65535).astype(numpy.uint8)
        print type(imageData[number][0][0])
        print imageData[number]        
                
        # Convert image data to image file
        im = Image.fromarray(imageData[number], 'I')
        im.save(pathOut+".gif")
        #im = Image.open(pathIn+".tiff")
        #im.save(pathIn+".bmp")


if 0:
    print "Select slide out of {0}".format(len(imageData))
    print ">>>",
    command = raw_input()
    while str(command) != "q":
        sliceData = imageData[int(command)]
        pyplot.imshow(sliceData)
        pyplot.show()

if 0:
    # Plot series' images
    pyplot.show()
    for key, sliceData in imageData.iteritems():
        print sliceData
        pyplot.imshow(sliceData)
        time.sleep(10)
        #print "b"
        #pyplot.close()