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
real :: xlapse = 6.5e-3_r8   ! Temperature lapse rate (K/m)
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
phis=oro*gravit
alpha = rair*xlapse/gravit
do j=1,nj
     do i=1,ni
        if ( abs(oro(i,j)) < 1.e-4_r8 )then
           ps(i,j)=psl(i,j)
        else
           Tstar=TS(i,j)

           TT0=Tstar + xlapse*oro(i,j)                  ! pg 8 eq 13

           if ( Tstar<=290.5_r8 .and. TT0>290.5_r8 ) then           ! pg 8 eq 14.1
              alph=rair/phis(i,j)*(290.5_r8-Tstar)  
           else if (Tstar>290.5_r8  .and. TT0>290.5_r8) then        ! pg 8 eq 14.2
              alph=0._r8
              Tstar= 0.5_r8 * (290.5_r8 + Tstar)  
           else  
              alph=alpha  
              if (Tstar<255._r8) then  
                 Tstar= 0.5_r8 * (255._r8 + Tstar)                  ! pg 8 eq 14.3
              endif
           endif

           beta = phis(i,j)/(rair*Tstar)
           ps(i,j)=psl(i,j)/exp( beta*(1._r8-alph*beta/2._r8+((alph*beta)**2)/3._r8))
        end if
     enddo
enddo

end subroutine invert_cpslec
