import os
def construct(logdir):
    # Construct data shown in document
    nplots_per_page = 1
    counter = 0
    pages_data = []
    temp = []
    
    # Get all plots
    files = sorted(os.listdir(logdir))

    # Iterate over all created visualization
    for fname in files:
        if counter == nplots_per_page:
            pages_data.append(temp)
            temp = []
            counter = 0

        temp.append(f'{logdir}/{fname}')
        counter += 1
    return [*pages_data, temp]
