from django.db import models

class Dicom(models.Model):
    base_dir = models.CharField(max_length=200)

class Patient(models.Model):
    dicom = models.ForeignKey(Dicom)
    patientId = models.CharField(max_length = 10)
    name = models.CharField(max_length = 10)
    birthdate = models.CharField(max_length = 10)
    sex = models.CharField(max_length = 10)
    
class Study(models.Model):
    dicom = models.ForeignKey(Dicom)
    date = models.CharField(max_length = 10)
    time = models.CharField(max_length = 10)
    accessionNumber = models.CharField(max_length = 10)
    description = models.CharField(max_length = 10)
    instanceUID = models.CharField(max_length = 10)
    studyId = models.CharField(max_length = 10)
    
class Series(models.Model):
    study = models.ForeignKey(Study)
    date = models.CharField(max_length = 10)
    time = models.CharField(max_length = 10)
    modality = models.CharField(max_length = 10)
    institutionName = models.CharField(max_length = 10)
    institutionAddress = models.CharField(max_length = 10)
    description = models.CharField(max_length = 10)
    instanceUID = models.CharField(max_length = 10)
    number = models.CharField(max_length = 10)

class Image(models.Model):
    series = models.ForeignKey(Series)
    fileID = models.CharField(max_length = 10)
    pixelSpacing = models.CharField(max_length = 10)
    rows = models.CharField(max_length = 10)
    columns = models.CharField(max_length = 10)
    instanceNumber = models.CharField(max_length = 10)
    pixelSpacing = models.CharField(max_length = 10)
    rows = models.CharField(max_length = 10)
    columns = models.CharField(max_length = 10)
    instanceNumber = models.CharField(max_length = 10)
    contentDate = models.CharField(max_length = 10)
    contentTime = models.CharField(max_length = 10)
    imagePosition = models.CharField(max_length = 10)
    imageOrientation = models.CharField(max_length = 10)