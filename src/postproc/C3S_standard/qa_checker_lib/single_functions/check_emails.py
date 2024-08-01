import re
def check_emails(fromaddr, toaddrs):
    """
    Check correctness of 2 email addresses provided.
    """
    regex = '^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$'
    if (re.search(regex,fromaddr)):
        pass
    else:  
        raise ProgramError('[PROGRAMERROR] in function check_emails(). Error in sender email')
    recipient=0
    while recipient < len(toaddrs.split(',')):
        if (re.search(regex,toaddrs.split(',')[recipient])):
            pass
        else:  
            raise ProgramError('[PROGRAMERROR] in function check_emails(). Error in recipient mail')
        recipient += 1

