import csv
import os
import numpy as np

caso=os.getenv("caso")
csvfile="/data/cmcc/cp1/temporary/CERISE_phase2_list.juno.20251015.csv"
with open(csvfile, mode ='r') as file:    
       csvFile = csv.DictReader(file)
       for lines in csvFile:
            if lines["CASO"] == caso:
                if np.int_(lines["month1"]) == 0:
                    print(0)
                else:
                    print(1)
               
