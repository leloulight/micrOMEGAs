
C====== Modules =================
C   Keys to switch on
C   various modules of micrOMEGAs
C================================
   
#define MASSES_INFO
C    Display information about masses of odd sector
#define CONSTRAINTS
C    This module is empty yet!
#define OMEGA
C    Calculate relic density and display contribution of
C                            individual channels 
#define INDIRECT_DETECTION
C     Compute spectra of gamma/positron/neutrinos
C     for DM annihilation; calculate <sigma*v> and
C     integrate gamma signal over DM galactic squared
C     density for given line of sight.
C!#define RESET_FORMFACTORS
C     Modify default nucleus form factors, 
C     DM velocity distribution,
C     A-dependence of Fermi-dencity.
#define CDM_NUCLEON 
C     Calculate amplitudes and cross-sections for
C     CDM-mucleon collisions 
C!#define CDM_NUCLEUS
C     Calculate number of events for 1kg*day
C     and recoil energy distibution for various nuclei

C#define DECAYS
C     Calculates particle widths and branchings


C#define CROSS_SECTIONS
C     Calculate cross sections and widths for
C      reactions specified by the user
 
C================ end of Modules  ======

C===== Options ========

#define SHOWPLOTS
C     Display  graphical plots on the screen

C===== End of DEFINE  settings ===== 


      IMPLICIT NONE
C! external functions 
#include "../sources/micromegas.fh"
#include "lib/pmodel.fh"

C! local  Parameters   
      INTEGER fast/1/
      REAL*8  Beps/1.E-5/,cut/0.01/
C Variables      
      INTEGER err
      REAL*8 Omega,OmegaAppr,Xf,val
      REAL*8  el,thallium
      INTEGER  narg,nw 
      character *100 argv
      character*10 cdmName
      integer spin2,charge3,cdim,PDGcdm
      character*10 allLib

      real*8 Pcm,cosmin, cosmax,rw
      integer cc(2),txtL(2),dim
      integer ntot,l, nin,nout
      character*6 name(4)
      real*8 mass(4)
      real*8 cs,width,Etest
      real*8  Emin,sigmaV,fi,dfi
      character*100 mess
      real*8 SpA(NZ),Spe(NZ),SpP(NZ)
      real*8 FluxA(NZ),FluxE(NZ),FluxP(NZ)
C for CDM_NUCLEON
      real*8  pA0(2),pA5(2),nA0(2),nA5(2),Nmass,SCcoeff,
     >ffS0P(3),ffS0N(3),ffbuff(3)

C  for CDM_NUCLEUS
      real*8  dNdE(200),rho,nEvents

C   to save the SLHA  input/output file  uncomment  
C*      call delFiles(0)
 
      write(*,*)
      write(*,*) '========= EWSB scale input For CPVMSSM ========='
      if(iargc().eq.0) then
         write(*,*)'Correct usage: ./main  <file with parameters>'
         write(*,*)'Example: ./main  data1.par' 
         stop
      endif

      call getarg(1,argv)                               
       
      err=readVarlHiggs(argv)

      if(err.eq.-1) then
          write(*,*) 'Can not open the file'
          stop
      endif

      if(err.gt.0) then
          write(*,*)'Wrong file contents at line ',err
          stop
      endif

      goto 101
100   STOP 'Wrong input' 
101   continue
C  To print list od variables uncomment   
C      CALL printVar(6)

C    to save results in SLHA format  use 
C     Call writeLesH('slha.out') 

      err=sortOddParticles(cdmName)
      if(err.ne.0) then
        write(*,*) 'Can t calculate ', cdmName
        STOP
      endif 

      PDGcdm=qNumbers(cdmName,spin2, charge3,  cdim)
      write(*,fmt="('Dark matter candidate is ', A5,'with spin=',
     >I1,'/2 mass=',1PE10.2)") cdmName, spin2,Mcdm

      if(charge3.ne.0) then 
         write(*,fmt="('DM has electric charge',I1,'/3')") charge3
         STOP
      endif

      if(cdim.ne.1) then 
         write(*,*) 'DM has color charge'
         STOP
      endif

#ifdef MASSES_INFO  
      write(*,*) '=== MASSES OF HIGGS AND SUSY PARTICLES: ===' 
      CALL printMasses(6,1)
#endif

#ifdef CONSTRAINTS
C   !not implemented yet!
#endif


#ifdef OMEGA
      write(*,*)
      write(*,*) '==== Calculation of relic density ====='
      write(*,*) 'Dark Matter candidate is ', cdmName                                   
      if(cdmName.ne.'~A') then
          write(*,*) 'A is not LSP'
      endif                                                               
      Omega=darkOmega(Xf,fast,Beps)
      write(*,'(a,3x,1PE10.2)') 'Omega=',Omega

      OmegaAppr=printChannels(Xf,cut,Beps,1,6)
#endif

#ifdef  INDIRECT_DETECTION
      write(*,*) 
      write(*,*) '=============== Indirect detection ==========='

C** Emin - energy cut in GeV
      Emin=1     
      Etest=Mcdm/2
C** fi angle of sight [rad], dfi - half of cone angle    
      fi=0.1
      dfi=0.05
      sigmaV=calcSpectrum(4+1,SpA,SpE,SpP,NULL,NULL,NULL,err)    
C  Returns  sigma*v in cm^3/sec.
C  SpX - calculated spectra of annihilation.
C  Use SpectdNdE(E, SpX) to calculate energy distribution in 1/GeV units.
      write(*,*)
      write(*,fmt="('sigma*v=',1PE8.2,'[cm^3/s]')") sigmaV

      write(*,*) 'Photons'
      call gammaFluxTab(fi,dfi, sigmaV, SpA,  FluxA)
      write(*,fmt="('Phonton flux  for angle of sight ',
     < F4.2,'[rad]')") fi
      write(*,fmt="('and spherical region described by cone with angle '
     >,F4.2,'[rad]' )") 2*dfi
#ifdef SHOWPLOTS      
      write(mess,fmt="('gamma flux[cm^2 s GeV]^{-1} at fi=',F4.2,
     > ' from cone with angle=',F4.2,'[rad]')")fi,dfi*2  
      err= displaySpectrum(FluxA,mess,Emin,Mcdm,1)
#endif
      write(*,fmt="('Photon flux =',1PE8.2,
     >'[cm^2 s GeV]^{-1} for E=',0PF5.1,'[GeV]')")
     > SpectdNdE(Etest, FluxA), Etest
 
      write(*,*) 'Positrons'
      call  posiFluxTab(Emin, sigmaV, SpE, FluxE)

#ifdef SHOWPLOTS      
      err=displaySpectrum(FluxE,'positron flux [cm^2 s sr GeV]^{-1}',
     >Emin,Mcdm,1)
#endif
      write(*,fmt="('Positron flux  = ',1PE8.2,
     >'[cm^2 sr s GeV]^{-1} for E=',0PF6.1,'[GeV]')")
     > SpectdNdE(Etest, FluxE),  Etest     

      write(*,*) 'antiProtons'
      call  pbarFluxTab(Emin, sigmaV, SpP,  FluxP)

#ifdef SHOWPLOTS      
      err=displaySpectrum(FluxP,'a-proton flux [cm^2 s sr GeV]^{-1}',
     >Emin,Mcdm,1)
#endif

      write(*,fmt="('Anti proton flux  = ',1PE8.2,
     >'[cm^2 sr s GeV]^{-1} for E=',0PF6.1,'[GeV]')")
     > SpectdNdE(Etest, FluxP),  Etest     
#endif

#ifdef RESET_FORMFACTORS

C   The user has approach to form factors  which specifies quark contents 
C   of  proton and nucleon via global parametes like
C      <Type>FF<Nucleon><q>
C   where <Type> can be "Scalar", "pVector", and "Sigma"; 
C         <Nucleon>     "P" or "N" for proton and neutron
C         <q>            "d", "u","s"
C
C   calcScalarFF( Mu/Md, Ms/Md, sigmaPiN[MeV], sigma0[MeV])  
C   calculates and rewrites Scalar form factors

      write(*,*) 'protonFF (default)  d, u, s ', 
     >       ScalarFFPd, ScalarFFPu,ScalarFFPs
      write(*,*) 'neutronFF(default)  d, u, s ', 
     >       ScalarFFNd, ScalarFFNu,ScalarFFNs                          
      write(*,*) '===========Redefinition of form factors========='  
      call calcScalarFF(0.553d0,18.9d0,70.d0,35.d0)
      write(*,*) 'protonFF (new)      d, u, s ', 
     >ScalarFFPd, ScalarFFPu,ScalarFFPs                           
      write(*,*) 'neutronFF(new)      d, u, s ', ScalarFFNd, 
     >ScalarFFNu,ScalarFFNs                    

C  Option to change parameters of DM velocity  distribution 

      call SetfMaxwell(220.d0,600.d0)
C    dN  ~  exp(-v^2/arg1^2)*Theta(v-arg2)  d^3v     
C    Earth velocity with respect to Galaxy defined by 'Vearth' parameter.
C    All parameters are  in [km/s] units.       
#endif


#ifdef  CDM_NUCLEON
      write(*,*)
      write(*,*) '==== Calculation of CDM-nucleons amplitudes  ====='   


      err=nucleonAmplitudes(NoLoop, pA0,pA5,nA0,nA5)
      write(*,*)'CDM-nucleon amplitudes:'
      write(*,fmt="(' proton:  SI=',1PE9.2,' SD=',E9.2)")pA0(1),pA5(1)
      write(*,fmt="(' neutron: SI=',1PE9.2,' SD=',E9.2)")nA0(1),nA5(1) 

C  nucleon mass
      Nmass=0.939d0

      SCcoeff=4/M_PI*3.8937966E8
     >*(Nmass*Mcdm/(Nmass+ Mcdm))**2
      write(*,*) 'CDM-nucleon cross sections[pb]:'

      write(*,fmt="(' proton  SI=',1PE9.2,' SD=',E9.2)")
     >                           SCcoeff*pA0(1)**2,3*SCcoeff*pA5(1)**2
      write(*,fmt="(' neutron SI=',1PE9.2,' SD=',E9.2)")
     >                           SCcoeff*nA0(1)**2,3*SCcoeff*nA5(1)**2
#endif


#ifdef CDM_NUCLEUS
      write(*,*)
      write(*,*)'=========  Direct Detection ==========='

      write(*,*) 'Ge:'

      nEvents=nucleusRecoil(Maxwell,73,Z_Ge,J_Ge73,
     >S00Ge73,S01Ge73,S11Ge73,FeScLoop,dNdE)
C  See '../sources/micromegas.h' for description of arguments
C  Instead of Maxwell  one can use 'fDvDelta' Delta-function
C  velocity distribution.
      write(*,fmt="('Total number of events=',1PE9.2,' /day/kg')") 
     >nEvents

      write(*,fmt=
     >"(' Number of events in 10 - 50 KeV region=',1PE9.2,' /day/kg')") 
     >cutRecoilResult(dNdE,10.d0,50.d0) 


#ifdef SHOWPLOTS
       err=displayRecoilPlot(dNdE,
     >           'Distribution of recoil energy of 73Ge',0.d0,199.d0)
#endif
       write(*,*)
       write(*,*) '131Xe:'  
       nEvents=nucleusRecoil(Maxwell,131,Z_Xe,J_Xe131,
     > S00Xe131,S01Xe131,S11Xe131,FeScLoop,dNdE)

      write(*,fmt=
     >"('Total number of events=',1PE9.2,' /day/kg')")nEvents
      write(*,fmt="(' Number of events in 10 - 50 KeV region=',
     >   1PE9.2, ' /day/kg')")cutRecoilResult(dNdE,1.d1,5.d1)


#ifdef SHOWPLOTS
      err=displayRecoilPlot(dNdE,
     >    'Distribution of recoil energy of 131Xe',0.d0,199.d0)
#endif

#endif

#ifdef DECAYS

      write(*,*)
      write(*,*)'======Calculations of widths======='

C      pname = "H";
      width=pWidth('H',txtL,dim)
      write(*,fmt="('H->',I1,'*x :  total width ',1PE8.2,'[GeV]')")
     >dim,width
      write(*,*)'and Branchings:'
      call printTxtList(txtL,6);

      width=pWidth('e3',txtL,dim)
      write(*,fmt="('e3->',I1,'*x :  total width ',1PE8.2,'[GeV]')")
     >dim,width
      write(*,*)'and Branchings:'
      call printTxtList(txtL,6);
      write(*,fmt="('Br(e1,N1,n3)=',F4.2)") findBr(txtL,"e1,N1,n3")

C      pname = "~W+";
      width=pWidth('~W+',txtL,dim)
      write(*,fmt="('~W+->',I1,'*x :  total width ',1PE8.2,'[GeV]')")
     >dim,width
      write(*,*)'and Branchings:'
      call printTxtList(txtL,6);


#endif


#ifdef CROSS_SECTIONS
      write(*,*)
      write(*,*)'======Calculations of cross sections======='

      Pcm=500
      cosmin=-0.99
      cosmax=0.99
      write(*,fmt="('Process e,E->2*x at Pcm= ',F6.1,'[GeV]')") Pcm
      call setHelicities(0.5D0,-0.51D0)
      call setHelicities(0.D0,0.D0)
      call newProcess('e1%,E1%->2*x','eE_2x',cc)
      if(cc(1).ne.0 ) then
        call procInfo1(cc,ntot,nin,nout)
        do l=1,ntot
          cs= cs22(cc,l,Pcm,cosmin,cosmax,err)
          if((err.eq.0) .and. (cs.ne.0)) then 
            call procInfo2(cc,l,name,mass)
            write(*,fmt='(A3,1x,A3,A4,A3,1x,A3,$)')
     >      name(1),name(2),' -> ', name(3),name(4)
            write(*,fmt="(1PE8.2,'[pb]')") cs
          endif 
        enddo
      endif     
#endif
        call killPlots
      END

