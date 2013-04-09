from django.db import models

class Dicom(models.Model):
    base_dir = models.CharField(max_length=200)

    def __unicode__(self):
        return self.base_dir

class Patient(models.Model):
    dicom = models.ForeignKey(Dicom)
    patientId = models.CharField(max_length = 100)
    name = models.CharField(max_length = 100)
    birthdate = models.CharField(max_length = 100)
    sex = models.CharField(max_length = 100)

    def __unicode__(self):
        return self.name
    
class Study(models.Model):
    patient = models.ForeignKey(Patient)
    studyId = models.CharField(max_length = 100)
    date = models.CharField(max_length = 100)
    time = models.CharField(max_length = 100)
    accessionNumber = models.CharField(max_length = 100)
    description = models.CharField(max_length = 100)
    instanceUID = models.CharField(max_length = 100)

    def __unicode__(self):
        return self.studyId
    
class Series(models.Model):
    study = models.ForeignKey(Study)
    date = models.CharField(max_length = 100)
    time = models.CharField(max_length = 100)
    modality = models.CharField(max_length = 100)
    institutionName = models.CharField(max_length = 100)
    institutionAddress = models.CharField(max_length = 100)
    description = models.CharField(max_length = 100)
    instanceUID = models.CharField(max_length = 100)
    number = models.CharField(max_length = 100)

    def __unicode__(self):
        return self.description

class Image(models.Model):
    series = models.ForeignKey(Series)
    fileID = models.CharField(max_length = 100)
    pixelSpacing = models.CharField(max_length = 100)
    rows = models.CharField(max_length = 100)
    columns = models.CharField(max_length = 100)
    instanceNumber = models.CharField(max_length = 100)
    contentDate = models.CharField(max_length = 100)
    contentTime = models.CharField(max_length = 100)
    imagePosition = models.CharField(max_length = 100)
    imageOrientation = models.CharField(max_length = 100)

    def __unicode__(self):
        return self.instanceNumber