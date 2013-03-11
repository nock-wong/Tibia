import dicom
import errno
import os
import subprocess

dicomdir = os.path.join("C:","\Users","Nick","Desktop","Tibia","data","input","Juan_Cantelejo")

# dcmdjpeg options dcmfile-in dcmfile-out
dcmdjpeg = os.path.join("C:","\dcmtk-bin","dcmjpeg","apps","Debug","dcmdjpeg.exe")

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

DICOM = os.path.join(dicomdir, "DICOMDIR")
ds = dicom.read_file(DICOM)

dirOut = os.path.join(dicomdir, "decompressed")

pixel_data = list()
for record in ds.DirectoryRecordSequence:
    if record.DirectoryRecordType == "IMAGE":
        # Extract the relative path to the DICOM file
        pathIn = os.path.join(dicomdir, *record.ReferencedFileID)
#        print record.ReferencedFileID
        make_sure_path_exists(os.path.join(dicomdir, "decompressed", *record.ReferencedFileID[0:-1]))
        pathOut = os.path.join(dicomdir, "decompressed", *record.ReferencedFileID)

        if 1:
	        # Decompress JPEG files
	        subprocess.call([dcmdjpeg, pathIn, pathOut])
	        
	        dcm = dicom.read_file(pathOut)

	        # Now get your image data
	        pixel_data.append(dcm.pixel_array)

print pixel_data