from django.contrib import admin

from dicom_web.models import Dicom, Patient, Study, Series, Image

class PatientInline(admin.TabularInline):
    model = Patient

class ImageInline(admin.TabularInline):
    model = Image

class DicomAdmin(admin.ModelAdmin):
    fields = ['base_dir']
    inlines = [PatientInline]

class SeriesAdmin(admin.ModelAdmin):
    inlines = [ImageInline]

admin.site.register(Dicom, DicomAdmin)
admin.site.register(Series, SeriesAdmin)
