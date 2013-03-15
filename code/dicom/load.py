import dicom
import errno
import os
import subprocess
import matplotlib.pyplot as pyplot

# dcmdjpeg options dcmfile-in dcmfile-out
dcmdjpeg = os.path.join("C:","\dcmtk-bin","dcmjpeg","apps","Debug","dcmdjpeg.exe")

patient = "Juan_Cantelejo"
dataDir = os.path.join("C:","\Users","Nick","Desktop","Tibia","data")
patientDir = os.path.join(dataDir,"input",patient)

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

dirOut = os.path.join(dataDir, "output", "decompressed")

dicom_data = list()

dicomDir = os.path.join(patientDir, "DICOMDIR")
ds = dicom.read_file(dicomDir)

# Search for relative image files
# Need to patch to read DICOMDIR
# https://code.google.com/p/pydicom/issues/detail?id=7

if 1:
    for record in ds.DirectoryRecordSequence:
        if record.DirectoryRecordType == "IMAGE":
            if 67283585 > int(record.ReferencedFileID[-1]) > 67283366:
            # Temporary hack to extract knee files
                # Extract the relative path to the DICOM file
                pathIn = os.path.join(patientDir, *record.ReferencedFileID)
                # Decompress JPEG files
                make_sure_path_exists(os.path.join(patientDir, "decompressed", *record.ReferencedFileID[0:-1]))
                pathOut = os.path.join(patientDir, "decompressed", *record.ReferencedFileID)
                subprocess.call([dcmdjpeg, pathIn, pathOut])
                # Now get your image data
                dcm = dicom.read_file(pathOut)
                dicom_data.append(dcm.pixel_array)

    # Display data
    for slice_data in dicom_data:
        print slice_data
        print type(slice_data)
        pyplot.imshow(slice_data)
        pyplot.show()


