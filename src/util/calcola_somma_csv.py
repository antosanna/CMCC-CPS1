import csv,sys

def somma_colonne(file_input, file_output):
    with open(file_input, 'r') as file_in:
        reader = csv.reader(file_in)
        data = list(reader)
    print(len(data[0]))

    # Inizializza una lista vuota per contenere le somme delle colonne
    sum_columns = [0] * (len(data[0]) - 1)

    # Calcola le somme delle colonne dalla terza riga in poi
    for row in data[3:]:
        for i, value in enumerate(row[1:], start=1):  # Inizia dalla seconda colonna
            try:
                sum_columns[i - 1] += float(value)
            except ValueError:
                pass  # Ignora i valori non numerici

    # Sostituisci gli elementi dalla seconda colonna in poi con le somme delle colonne
    for i, sum_value in enumerate(sum_columns, start=1):
        data[1][i] = sum_value

    # Scrivi il risultato nel file di output
    with open(file_output, 'w', newline='') as file_out:
        writer = csv.writer(file_out)
        writer.writerows(data)

# Esempio d'uso
if __name__ == "__main__":
    file_input=str(sys.argv[1])  ; file_output=str(sys.argv[2])
    somma_colonne(file_input, file_output)

