! module load gcc-12.2.0/12.2.0
!compile WRAPIT extrapTZ_SPS4.stub extrapTZ_SPS4.f90
! see also utils/interpolate_data.F90 CAM (same algorithm)
subroutine vertinterp (nlevp,pnew,ni,nj,nk,nt,Tout,doT,Zout,doZ,PS,ts,oro) !,alnpout)
!real:: zmask3d(ni,nj,nlevp,nt)
real:: pnew(nlevp)
real:: hgt,alnp1,alnp2
real:: oro(ni,nj)
real:: ts(ni,nj,nt)
real:: PS(ni,nj,nt)
integer:: doT,doZ
! input-output variables
real:: Tout(ni,nj,nk,nt),Zout(ni,nj,nk,nt)
! NCLEND
!
!where mask do extrapolation
PS=PS*0.01
Rd=287.04
g=9.80626
alpha=0.0065*Rd/g
! time index 
do l=1,nt 
! these are the 2 plevs 1000., 925.where extrap is to do
   do k=1,nlevp  
      do j=1,nj
         do i=1,ni
! apply correction only over masked (=0) regions
            if(PS(i,j,l).lt.pnew(k)) then
! lowest level model pressure in mb
               PSFCMB=PS(i,j,l)
               TSTAR=ts(i,j,l)
               hgt=oro(i,j)
               if(doT.eq.1)then 
                  if (hgt.lt.2000.)then
                     alnp=alpha*log(pnew(k)/PSFCMB)
                  else
                     T0=TSTAR+0.0065*hgt
                     TPLAT=T0
                     if( T0.gt.298.) then
                        TPLAT=298.
                     end if
                     if (hgt.le.2500.) then
                        Tprime=0.002*((2500.-hgt)*T0+(hgt-2000.)*TPLAT)
! ((2500.-hgt)*T0+(hgt-2000.)*TPLAT)/500.
                     else
                        Tprime=TPLAT
                     end if
                     if ( Tprime.lt.TSTAR) then
                        alnp=0.
                     else
                        alnp=Rd*(Tprime-TSTAR)/(hgt*g)*log(pnew(k)/PSFCMB)
                     end if
                  end if
                  Tout(i,j,k,l)=TSTAR*(1+alnp+.5*alnp**2+1./6.*alnp**3)
               end if
! now for Z3
               if(doZ.eq.1)then
                  T0=TSTAR+0.0065*hgt
                  if(TSTAR.le.290.5.and.T0.gt.290.5) then
                     alph=Rd/(hgt*g)*(290.5-TSTAR)
                  else if (TSTAR.gt.290.5.and.T0.gt.290.5)then
                     alph=0.
                     TSTAR=.5*(290.5+TSTAR)
                  else
                     alph=alpha
                  end if
                  if(TSTAR.le.255.)then
                     TSTAR=.5*(255.+TSTAR)
                  end if
                  alnp=alph*log(pnew(k)/PSFCMB)
                  Zout(i,j,k,l)=hgt-Rd*TSTAR/g*log(pnew(k)/PSFCMB)*(1+.5*alnp+(1./6.)*(alnp**2))
               end if
           end if
! loop in lon
        end do
! loop in lat
     end do
! loop in plev
   end do
! loop in time
end do

end subroutine vertinterp
