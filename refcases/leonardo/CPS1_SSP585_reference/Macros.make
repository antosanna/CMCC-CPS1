
# This file is auto-generated, do not edit. If you want to change
# sharedlib flags, you can edit the cmake_macros in this case. You
# can change flags for specific sharedlibs only by checking COMP_NAME.

AR := xiar
ARFLAGS := cru
CFLAGS :=  -qno-opt-dynamic-align -fp-model precise -std=gnu99 -O2 -debug minimal -qmkl=cluster -qopt-zmm-usage=high -no-fma  -march=native 
CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DNO_R16 -DHAVE_NANOTIME
CXXFLAGS :=  -qmkl=cluster -qopt-zmm-usage=high -no-fma  -march=native 
CXX_LDFLAGS :=  -cxxlib
CXX_LINKER := FORTRAN
FC_AUTO_R8 := -r8
FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal -qmkl=cluster -qopt-zmm-usage=high -no-fma  -march=native 
FFLAGS_NOOPT := -O0
FIXEDFLAGS := -fixed
FREEFLAGS := -free
LDFLAGS :=  -L/leonardo/pub/usera07cmc/a07cmc00/spack-0.21.0-05/install/linux-rhel8-icelake/oneapi-2023.2.0/xerces-c-3.2.4-fy6ksf635ybje53u65jqeyncj2djeeyu/lib/ -lxerces-c 
MACRO_FILE := 
MPICC := mpiicc
MPICXX := mpiicpc
MPIFC := mpiifort
NETCDF_PATH := /leonardo/pub/usera07cmc/a07cmc00/spack-0.21.0-05/install/linux-rhel8-icelake/intel-2021.10.0/netcdf-c-4.9.2-7dk3jthfs6ggjmeud6q7s6kzr5n5tvr4
PIO_FILESYSTEM_HINTS := lustre
PNETCDF_PATH := /leonardo/pub/usera07cmc/a07cmc00/spack-0.21.0-05/install/linux-rhel8-icelake/intel-2021.10.0/parallel-netcdf-1.12.3-buqtawhw64qwwthvtl4iapow2xj7pvwm
SCC := icc
SCXX := icpc
SFC := ifort
SLIBS := $(SLIBS)  -qmkl=cluster
SUPPORTS_CXX := TRUE

ifeq "$(COMP_NAME)" "nemo"
  FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal $(FC_AUTO_R8) -O3 -assume norealloc_lhs -qmkl=cluster -qopt-zmm-usage=high -no-fma  -march=native 
endif
