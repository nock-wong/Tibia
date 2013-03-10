import dicom
import os

dicomdir = "C:\Users\Nick\Desktop\Tibia\data\input\Juan_Cantelejo"

ds = dicom.read_file("{dir}/DICOMDIR".format(dir=dicomdir))

pixel_data = list()

for record in ds.DirectoryRecordSequence:
    if record.DirectoryRecordType == "IMAGE":
        # Extract the relative path to the DICOM file
        path = os.path.join(dicomdir, *record.ReferencedFileID)
        dcm = dicom.read_file(path)

        # Now get your image data
        pixel_data.append(dcm.pixel_array)

print pixel_data