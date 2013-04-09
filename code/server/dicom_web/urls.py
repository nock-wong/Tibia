from django.conf import settings
from django.conf.urls import patterns, url
from django.conf.urls.static import static

from dicom_web import views

urlpatterns = patterns('',
    url(r'^$', views.index, name='index'),
    url(r'^upload/$', views.upload, name='upload'),
    url(r'^view_dicom/$', views.view_dicom, name='view_dicom'),
    url(r'^view_series/$', views.view_series, name='view_series'), 
    url(r'^view_slide/$', views.view_slide, name='view_slide'),   
)