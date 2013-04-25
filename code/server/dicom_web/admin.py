from django.contrib import admin

from dicom_web.models import Dicom, Patient, Study, Series, Image

class PatientInline(admin.TabularInline):
    model = Patient

class StudyInline(admin.TabularInline):
    model = Study

class SeriesInline(admin.TabularInline):
    model = Series

class ImageInline(admin.TabularInline):
    model = Image

class DicomAdmin(admin.ModelAdmin):
    fields = ['base_dir']
    inlines = [PatientInline]

class PatientAdmin(admin.ModelAdmin):
    inlines = [StudyInline]

class StudyAdmin(admin.ModelAdmin):
    inlines = [SeriesInline]

class SeriesAdmin(admin.ModelAdmin):
    inlines = [ImageInline]

admin.site.register(Dicom, DicomAdmin)
admin.site.register(Patient, PatientAdmin)
admin.site.register(Study, StudyAdmin)
admin.site.register(Series, SeriesAdmin)
