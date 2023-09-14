// READSLIMOUT3_SLIM3.c

#include "libhdr"

#define NN 300000 // Maximum 150000 SNPs segregating
#define CC 2001   // Maximum N=1000 individuals
#define MC 50000 // Maximum 40000 SNPs per chromosome

int i, j, s, m, x, nind, HOM1, HOM2, NCHR, genomelen;
int a, b, ss;
int mut[NN], pos[NN], crom[CC][MC], num_mut_crom[CC];

double w, ps[NN], h[NN], q[NN], cMMb;
int numSNP;
char ch;

FILE *fdat, *fgen, *fPpos, *fallsnps;

main()
{
	getintandskip("NIND :",&nind,1,2000);
	getintandskip("Genome length :",&genomelen,1,infinity);
	getintandskip("NCHR :",&NCHR,1,infinity);
	getrealandskip("cMMb :",&cMMb,0.0,(double)infinity);

	readfiles();
	PLINK_files();

	return(0);
}

/* **************************************************************************** */

readfiles()
{
	fgen = fopen ("dataBP.ped","w");

	// PLINK FILES
	fPpos = fopen ("dataBP.map","w");

	fallsnps = fopen ("list_allsnps","w");

	// ********** Read slimout to get SNP positions, effects and frequencies ********** 

	fdat = fopen ("slimout","r");

	// ********** gets the position, effects and frequencies of all mutations simulated (numSNP) **********

	lookfortext("Mutations:");

	while (!feof(fdat))
	{
		s ++;
		fscanf(fdat,"%d", &x);
		mut[s] = x;
		fscanf(fdat,"%d", &x);
		for (j=1; j<=4; j++)	fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%d", &x);
		pos[s] = x;
		fscanf(fdat,"%lf", &w);
		ps[s] = w;
		fscanf(fdat,"%lf", &w);
		h[s] = w;
		for (j=1; j<=4; j++)	fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%d", &x);
		fscanf(fdat,"%d", &x);
		q[s] = x / (2.0*nind);
		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%c", &ch);
		if (ch != 'I')	ungetc(ch, fdat);
		else		break;
	}
	numSNP = s;

	fclose(fdat);

	// ********** reorder by genome position **********

	for (s=1; s<numSNP; s++)
	for (ss=s; ss<=numSNP; ss++)
	{
		if (pos[ss] < pos[s])
		{
			b=pos[s]; pos[s]=pos[ss]; pos[ss]=b;
			b=mut[s]; mut[s]=mut[ss]; mut[ss]=b;
			w=ps[s]; ps[s]=ps[ss]; ps[ss]=w;
			w=h[s]; h[s]=h[ss]; h[ss]=w;
			w=q[s]; q[s]=q[ss]; q[ss]=w;
		}
	}

//	for (s=1; s<=numSNP; s++)	printf("s=%d mut=%d pos=%d\n", s, mut[s], pos[s]);

	// ********** gets mutations **********

	fdat = fopen ("slimout","r");
	lookfortext("Genomes:");

	fscanf(fdat,"%c", &ch);

	for (i=1; i<=(2*nind);i++)
	{
		m = 0;

		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%d", &x);
		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%c", &ch);
		fscanf(fdat,"%c", &ch);
		if (ch == '\n')	goto next;
		else	ungetc(ch, fdat);
		while (!feof(fdat))
		{
			fscanf(fdat,"%c", &ch);

			if (ch == '\n')	break;
			else
			{
				ungetc(ch, fdat);
				m ++;
				fscanf(fdat,"%d", &x);
				crom[i][m] = x;
			}			
		}
		num_mut_crom[i] = m;

		next: /***/;
	}

	fclose(fdat);

	return(0);
}

/* **************************************************************************** */

PLINK_files()
{
	double sum, sum2;

	for (i=1; i<(2*nind);i+=2)
	{
		if (i%2 != 0)
		{
			fprintf(fgen,"1 IND%d 0 0 1 -9 ", (i+1)/2);
		}
		for (s=1; s<=numSNP; s++)
		{
			if (i == 1)
			{
				// PLINK POSFILE
				fprintf(fPpos,"%d SNP%d %f %d\n", (pos[s]/(genomelen/NCHR))+1, s, (double)pos[s]*cMMb/1000000.0, pos[s]);
			}
			HOM1 = 0; HOM2 = 0;

			for (m=1; m<=num_mut_crom[i]; m++)
			{
				if (crom[i][m] == mut[s])
				{
					HOM1 = 1;
					break;
				}
			}
			for (m=1; m<=num_mut_crom[i+1]; m++)
			{
				if (crom[i+1][m] == mut[s])
				{
					HOM2 = 1;
					break;
				}
			}

			if ((HOM1==0) && (HOM2==0))
			{
				fprintf(fgen,"A A ");
			}
			else if ((HOM1==1) && (HOM2==0))
			{
				fprintf(fgen,"T A ");
			}
			else if ((HOM1==0) && (HOM2==1))
			{
				fprintf(fgen,"A T ");
			}
			else
			{
				fprintf(fgen,"T T ");
			}

			// Assignment of alleles to SNPs to get gamete types
		}
		fprintf(fgen,"\n");

	}

	// List all SNPs
//	fprintf(fallsnps,"SNP   pos\n");
	fprintf(fallsnps,"%d\n", numSNP);
	for (s=1; s<=numSNP; s++)	fprintf(fallsnps,"%d  %d  %f  %f  %f\n", s, pos[s], ps[s], h[s], q[s]);

	return(0);
}

/* **************************************************************************** */

lookfortext(s)
char *s;
{
   int len, i, curchar;
   char c;

   curchar = 0;
   len = 0;

   for (i=0; i<=100; i++)
   {
      if (s[i] == '\0') break;
      len++;
   }
   do
   {
      c = getc(fdat);

      if (c==s[curchar])
      {
         curchar++;
         if (curchar==len) return(0);
      }
      else curchar = 0;
   }
   while (c != EOF);
}

/* ********************************************************************************************* */

