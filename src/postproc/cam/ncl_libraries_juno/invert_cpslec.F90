!module load gcc-12.2.0/12.2.0
!compile WRAPIT invert_cpslec.stub invert_cpslec.F90
subroutine invert_cpslec (ni,nj, oro, ps, TS, psl)

!----------------------------------------------------------------------- 
! 
! Purpose: 
! Hybrid coord version:  Compute ps from sea level pressure 
! 
! Method: 
! CCM2 hybrid coord version using ECMWF formulation
! Algorithm: See section 3.1.b in NCAR NT-396 "Vertical 
! Interpolation and Truncation of Model-Coordinate Data
!
! Author: Stolen from cpslec cam
! 
!-----------------------------------------------------------------------
!
! $Id$
! $Author$
!
!-----------------------------------------------------------------------

!-----------------------------Arguments---------------------------------

real :: oro(ni,nj)      ! Surface geopotential (m**2/sec**2)
real :: psl(ni,nj)        ! Sea Level pressure (pascals)
real :: TS(ni,nj)    ! Tstar
real :: ps(ni,nj)       ! Surface pressures (pascals)
!-----------------------------------------------------------------------

!-----------------------------Parameters--------------------------------
real :: xlapse    ! Temperature lapse rate (K/m)
real :: gravit           ! Gravitational acceleration
real :: rair             ! gas constant for dry air
!-----------------------------------------------------------------------

!-----------------------------Local Variables---------------------------
real :: phis(ni,nj)      ! Surface geopotential (m**2/sec**2)
integer i              ! Loop index
real alpha         ! Temperature lapse rate in terms of pressure ratio (unitless)
real TT0           ! Computed temperature at sea-level
real alph          ! Power to raise P/Ps to get rate of increase of T with pressure
real beta          ! alpha*oro/(R*T) term used in approximation of PSL
!-----------------------------------------------------------------------
!
rair=1.38065e-23*6.02214e26/28.966
xlapse = 6.5e-3   ! Temperature lapse rate (K/m)
gravit=9.80616
phis=oro*gravit
alpha = rair*xlapse/gravit
do j=1,nj
     do i=1,ni
        if ( abs(oro(i,j)) .lt. 1.e-4 )then
           ps(i,j)=psl(i,j)
        else
           Tstar=TS(i,j)

           TT0=Tstar + xlapse*oro(i,j)                  ! pg 8 eq 13

           if ( Tstar.le.290.5 .and. TT0.gt.290.5 ) then           ! pg 8 eq 14.1
              alph=rair/phis(i,j)*(290.5-Tstar)  
           else if (Tstar.gt.290.5  .and. TT0.gt.290.5) then        ! pg 8 eq 14.2
              alph=0.
              Tstar= 0.5 * (290.5 + Tstar)  
           else  
              alph=alpha  
              if (Tstar.lt.255.) then  
                 Tstar= 0.5 * (255. + Tstar)                  ! pg 8 eq 14.3
              end if
           end if

           beta = phis(i,j)/(rair*Tstar)
           ps(i,j)=psl(i,j)/exp( beta*(1.-alph*beta/2.+((alph*beta)**2)/3.))
        end if
     enddo
enddo

end subroutine invert_cpslec
