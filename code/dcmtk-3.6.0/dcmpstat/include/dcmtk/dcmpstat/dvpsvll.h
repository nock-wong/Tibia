/*
 *
 *  Copyright (C) 1998-2010, OFFIS e.V.
 *  All rights reserved.  See COPYRIGHT file for details.
 *
 *  This software and supporting documentation were developed by
 *
 *    OFFIS e.V.
 *    R&D Division Health
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *
 *  Module: dcmpstat
 *
 *  Author: Marco Eichelberg
 *
 *  Purpose:
 *    classes: DVPSVOILUT_PList
 *
 *  Last Update:      $Author: joergr $
 *  Update Date:      $Date: 2010-10-14 13:16:37 $
 *  CVS/RCS Revision: $Revision: 1.11 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#ifndef DVPSVLL_H
#define DVPSVLL_H

#include "dcmtk/config/osconfig.h"    /* make sure OS specific configuration is included first */
#include "dcmtk/dcmdata/dcitem.h"

class DVPSVOILUT;


/** the list of VOI LUTs contained in an image attached to a presentation state.
 *  This class manages the data structures comprising the VOI LUT Sequence
 *  of one image attached to a presentation state.
 */

class DVPSVOILUT_PList
{
public:
  /// default constructor
  DVPSVOILUT_PList();

  /// copy constructor
  DVPSVOILUT_PList(const DVPSVOILUT_PList& copy);

  /** clone method.
   *  @return a pointer to a new DVPSVOILUT_PList object containing
   *  a deep copy of this object.
   */
  DVPSVOILUT_PList *clone() { return new DVPSVOILUT_PList(*this); }

  /// destructor
  virtual ~DVPSVOILUT_PList();

  /** reads a list of VOI LUTs from a DICOM dataset.
   *  The DICOM elements of the VOI LUT Sequence are copied
   *  from the dataset to this object.
   *  The completeness of the item (presence of all required elements,
   *  value multiplicity) is checked.
   *  If this method returns an error code, the object is in undefined state afterwards.
   *  @param dset the dataset from which the VOI LUT Sequence is to be read
   *  @return EC_Normal if successful, an error code otherwise.
   */
  OFCondition read(DcmItem &dset);

  /** reset the object to initial state.
   *  After this call, the object is in the same state as after
   *  creation with the default constructor.
   */
  void clear();

  /** get number of VOI LUTs in this list.
   *  @return the number of VOI LUTs.
   */
  size_t size() const { return list_.size(); }

  /** returns a pointer to the VOI LUT with the given
   *  index or NULL if it does not exist.
   *  @param idx index, must be < size()
   *  @return pointer to VOI LUT or NULL
   */
  DVPSVOILUT *getVOILUT(size_t idx);

private:

  /// private undefined assignment operator
  DVPSVOILUT_PList& operator=(const DVPSVOILUT_PList&);

  /** the list maintained by this object
   */
  OFList<DVPSVOILUT *> list_;
};

#endif

/*
 *  $Log: dvpsvll.h,v $
 *  Revision 1.11  2010-10-14 13:16:37  joergr
 *  Updated copyright header. Added reference to COPYRIGHT file.
 *
 *  Revision 1.10  2010-10-07 14:31:36  joergr
 *  Removed leading underscore characters from preprocessor symbols (reserved).
 *
 *  Revision 1.9  2009-11-24 14:12:58  uli
 *  Switched to logging mechanism provided by the "new" oflog module.
 *
 *  Revision 1.8  2009-09-30 10:42:38  uli
 *  Make dcmpstat's include headers self-sufficient by including all
 *  needed headers directly and stop using dctk.h
 *
 *  Revision 1.7  2005-12-08 16:04:12  meichel
 *  Changed include path schema for all DCMTK header files
 *
 *  Revision 1.6  2003/06/04 10:18:06  meichel
 *  Replaced private inheritance from template with aggregation
 *
 *  Revision 1.5  2001/09/26 15:36:18  meichel
 *  Adapted dcmpstat to class OFCondition
 *
 *  Revision 1.4  2001/06/01 15:50:25  meichel
 *  Updated copyright header
 *
 *  Revision 1.3  2000/06/02 16:00:54  meichel
 *  Adapted all dcmpstat classes to use OFConsole for log and error output
 *
 *  Revision 1.2  2000/03/08 16:28:59  meichel
 *  Updated copyright header.
 *
 *  Revision 1.1  1998/12/22 17:57:09  meichel
 *  Implemented Presentation State interface for overlays,
 *    VOI LUTs, VOI windows, curves. Added test program that
 *    allows to add curve data to DICOM images.
 *
 *
 */
