import csv,sys

def sostituisci_valore(file_input, file_output, numero_riga, ncol, nuovo_valore):
    with open(file_input, 'r') as file_in:
        reader = csv.reader(file_in)
        data = list(reader)

    # Assicurati che il numero di riga fornito sia valido
    if 0 <= numero_riga < len(data):
        # Sostituisci il valore dalla seconda colonna in poi nella riga specificata
#        e nelle colonne definite in input
        for i in range(1, ncol):
            data[numero_riga][i] = nuovo_valore
    else:
        print("Numero di riga non valido.")

    # Scrivi il risultato nel file di output
    with open(file_output, 'w', newline='') as file_out:
        writer = csv.writer(file_out)
        writer.writerows(data)

if __name__ == "__main__":
#    nargs=len(sys.argv)
    file_input=str(sys.argv[1])  ; ncol=int(sys.argv[2])+1;numero_riga=int(sys.argv[3])-1
    file_output =  file_input
    nuovo_valore = 1  # Cambia con il nuovo valore da inserire

    sostituisci_valore(file_input, file_output, numero_riga, ncol, nuovo_valore)

