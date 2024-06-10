import csv
from argParser import argParser

def main():
    args=argParser()
    st=args.startdate
    iy=args.year
    csvfile=args.csvfile
    cases=[]
    with open(csvfile) as infile:
         reader=csv.DictReader(infile)
         for _ in range(1):
             pass
         for row in reader:
             if iy+st+"_0" in row["CASO"] and int(row["month6"]) == 0:
                if "_031" in row["CASO"]:
                    quit()
                print((row["CASO"]))

if __name__=="__main__":
    main()
