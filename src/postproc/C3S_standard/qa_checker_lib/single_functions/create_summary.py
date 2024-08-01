import os
import shutil
from fpdf import FPDF
from plot_mean_field import plot_mean_field
from plot_max_field import plot_max_field
from plot_min_field import plot_min_field
from plot_time_series_field import plot_time_series_field
from plot_clim_error_point import plot_clim_error_point

def create_summary(fullfield, field, table_values, logdir, lab_std, lab_mem, filename, logo, verbose=False, very_verbose=False):
    """
    Creates a small set of summary plots for each variable by level/realization: mean, max, min, global time series
    check how to create reports on https://towardsdatascience.com/how-to-create-pdf-reports-with-python-the-essential-guide-c08dd3ebf2ee
    """
    if verbose:
        print('....Creating summary report')

    sumdir = os.path.join(logdir,"summary")

    # Delete folder if exists and create it again
    try:
        shutil.rmtree(sumdir)
        os.mkdir(sumdir)
    except FileNotFoundError:
        os.mkdir(sumdir)

    # create plots
    if 'levname' in globals():
        for lev in range(0,len(field[levname])):
            if very_verbose:
                print('Plot monthly mean lev '+str(lev))
            plot_type="1"
            plotname="plot_"+plot_type+"_lev_"+str(lev).zfill(3)+".png"
            plot_mean_field(fullfield, field.isel(plev=lev), varname+' ('+field.units+') Mean at plev '+str(lev), sumdir, plotname)

            if very_verbose:
                print('Plot monthly max lev '+str(lev))
            plot_type="2"
            plotname="plot_"+plot_type+"_lev_"+str(lev).zfill(3)+".png"
            plot_max_field(fullfield, field.isel(plev=lev), varname+' ('+field.units+') Maximum at plev '+str(lev), sumdir, plotname)

            if very_verbose:
                print('Plot monthly min lev '+str(lev))
            plot_type="3"
            plotname="plot_"+plot_type+"_lev_"+str(lev).zfill(3)+".png"
            plot_min_field(fullfield, field.isel(plev=lev), varname+' ('+field.units+') Minimum at plev '+str(lev), sumdir, plotname)

            if very_verbose:
                print('Plot mean time series lev '+str(lev))
            plot_type="4"
            plotname="plot_"+plot_type+"_lev_"+str(lev).zfill(3)+".png"
            plot_time_series_field(fullfield, field.isel(plev=lev), varname+' ('+field.units+') Global mean at plev '+str(lev), sumdir, plotname)
    
        #DEV: add vertical profile
        # if very_verbose:
        #     print('Plot vertical profile')
        # plot_type="6"
        # plotname="plot_"+plot_type+".png"
        # title=varname+' ('+field.units+') Global vertical profile'
        # plot_vertical_profile(fullfield, field, title , sumdir, plotname)

    else:
        if very_verbose:
            print('Plot monthly mean')
        plot_type="1"
        plotname="plot_"+plot_type+".png"
        plot_mean_field(fullfield, field, varname+' ('+field.units+') Mean', sumdir, plotname)

        if very_verbose:
            print('Plot monthly max')
        plot_type="2"
        plot_mean_field(fullfield, field, varname+' ('+field.units+') Mean', sumdir, plotname)

        if very_verbose:
            print('Plot monthly max')
        plot_type="2"
        plot_mean_field(fullfield, field, varname+' ('+field.units+') Mean', sumdir, plotname)

        if very_verbose:
            print('Plot monthly max')
        plot_mean_field(fullfield, field, varname+' ('+field.units+') Mean', sumdir, plotname)

        if very_verbose:
            print('Plot monthly max')
        plot_type="2"
        plot_mean_field(fullfield, field, varname+' ('+field.units+') Mean', sumdir, plotname)

        if very_verbose:
            print('Plot monthly max')
        plot_type="2"
        plotname="plot_"+plot_type+".png"
        plot_max_field(fullfield, field, varname+' ('+field.units+') Maximum', sumdir, plotname)

        if very_verbose:
            print('Plot monthly min')
        plot_type="3"
        plotname="plot_"+plot_type+".png"
        plot_min_field(fullfield, field, varname+' ('+field.units+') Minimum', sumdir, plotname)

        if very_verbose:
            print('Plot mean time series')
        plot_type="4"
        plotname="plot_"+plot_type+".png"
        plot_time_series_field(fullfield, field, varname+' ('+field.units+') Global mean', sumdir, plotname)

    #DEV: you might add here as many plots as you want, just be careful to name them with increasing numbering and they will be added to the summary ordered
    #DEV: new plots should be included as functions that may be specific for certain variables (i.e., for ice variables plots can be in polar projection)
    #DEV: colormap and colorbar limits might be included in the json table as a dictionary for each variable

    if table_values:
        if very_verbose:
            print('Plot clim error points')
        plot_type="5"
        plotname="plot_"+plot_type+".png"
        plot_clim_error_point(fullfield, field, table_values, varname+' ('+field.units+') Clim error points ', sumdir, plotname)
    #DEV: tricky option is to include plots only on error positions...
    #     Try here to create a plot based on table_values
    #     Otherwise, maybe I can add a global plot counter (or a list of plot filenames created)
    #     in order to be able to call the plotting function directly from the check functions in case of error.
    #     Then collect here also these plots and add them to the report?

    # collect plots to add to report
    plots_per_page = construct(sumdir)
    
    #create PDF report
    pdf = PDF('L', filename, logo)

    for elem in plots_per_page:
        pdf.print_page(elem)

    # save to file
    report_filename=os.path.join(sumdir,'qa_checker_summary_report_'+shortname+'_'+lab_std+'_'+lab_mem+'.pdf')
    pdf.output(report_filename, 'F')
