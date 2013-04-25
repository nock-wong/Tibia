from django.conf import settings
from django.conf.urls import patterns, url
from django.conf.urls.static import static

from dicom_web import views

urlpatterns = patterns('',
    url(r'^$', views.index, name='index'),
    url(r'^(?P<dicom_id>\d+)/$', views.view_dicom, name='view_dicom'),
    url(r'^(?P<dicom_id>\d+)/(?P<series_id>\d+)/(?P<image_index>\d+)/$', views.view_series, name='view_series'),
    url(r'^upload/$', views.upload, name='upload'),
)