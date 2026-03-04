
# This file is auto-generated, do not edit. If you want to change
# sharedlib flags, you can edit the cmake_macros in this case. You
# can change flags for specific sharedlibs only by checking COMP_NAME.

AR := xiar
ARFLAGS := cru
CFLAGS :=  -qno-opt-dynamic-align -fp-model precise -std=gnu99 -O2 -debug minimal -qmkl=cluster -march=icelake-client -mtune=icelake-client -qopt-zmm-usage=high -no-fma 
CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DNO_R16 -DHAVE_NANOTIME
CXX_LDFLAGS :=  -cxxlib
CXX_LINKER := FORTRAN
FC_AUTO_R8 := -r8
FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal -qmkl=cluster -march=icelake-client -mtune=icelake-client -qopt-zmm-usage=high -no-fma 
FFLAGS_NOOPT := -O0
FIXEDFLAGS := -fixed
FREEFLAGS := -free
LDFLAGS :=  -L/juno/opt/spacks/0.20.0/opt/spack/linux-rhel8-icelake/intel-2021.6.0/xerces-c/3.2.3-witntw6kh77tp7mqhlrvpk2ezimigecm/lib/ -lxerces-c 
MACRO_FILE := 
MPICC := mpiicc
MPICXX := mpiicpc
MPIFC := mpiifort
NETCDF_PATH := /juno/opt/spacks/0.20.0/opt/spack/linux-rhel8-icelake/intel-2021.6.0/intel-oneapi-mpi-2021.6.0/netcdf-c/4.9.0-qbuoy54nahnlx3p6ete6a3vp4otmifjw
PIO_FILESYSTEM_HINTS := gpfs
PNETCDF_PATH := /juno/opt/spacks/0.20.0/opt/spack/linux-rhel8-icelake/intel-2021.6.0/intel-oneapi-mpi-2021.6.0/parallel-netcdf/1.12.3-eshb5fyfcgnsdtajnwbrnooe7mvsdcac
SCC := icc
SCXX := icpc
SFC := ifort
SLIBS := $(SLIBS)  -qmkl=cluster -qmkl=cluster -lstdc++ -l:libparmetis.a -l:libmetis.a 
SUPPORTS_CXX := TRUE

ifeq "$(COMP_NAME)" "nemo"
  FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal $(FC_AUTO_R8) -O3 -assume norealloc_lhs -qmkl=cluster -march=icelake-client -mtune=icelake-client -qopt-zmm-usage=high -no-fma 
endif
