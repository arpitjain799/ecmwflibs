#!/usr/bin/env python3

import os
from Magics import macro as magics

name = 'magics'
# Setting of the output file name
output = magics.output(output_formats=['png'],
                       output_name_first_page_number="off",
                       output_name="magics")

if not os.path.exists('2m_temperature.grib'):
    os.system('wget http://download.ecmwf.int/test-data/magics/2m_temperature.grib')
# Import the  data
data = magics.mgrib(grib_input_file_name="2m_temperature.grib", )

proj = magics.mmap(subpage_map_projection='mollweide')


# Apply an automatic styling
contour = magics.mcont(contour_automatic_setting="ecmwf", )
coast = magics.mcoast()
magics.plot(output, proj, data, contour, coast)
