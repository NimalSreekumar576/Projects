#include<stdio.h>
#include<math.h>
#include<stdlib.h>

//Defining the parameters
double length=6e-6;
double Na= 1e21,Nd=1e20,Nv=1.04e25,Nc=2.8e25;
double q = 1.6e-19;
double kB = 1.38e-23;
double T=300;
double epsi = 11.7*8.854e-12;
int N=100;
double dx ;
double V_app=0;
double E_g = 1.12*1.6e-19;
double tol =1e-6;
double n_i= 1e16;
double t_p =1e-7, t_n = 5e-7;
int it = 1;

//Defining Bernoulli function
double B(double z){
    return z/(exp(z)-1);
}

int main(){
    dx= length/(N-1);
    /*Section 1: Poisson's eqn solver*/
    double rho[N];
    double V[N];
    double phi[N];
    double J_n[N], J_p[N];
    //Defining the array of voltages to be zero and defining the array of phi
    for(int i=1;i<N-1; i++){
        V[i] =0;
        phi[i]= q*V[i]/(kB*T);
    }

    //Boundary Conditions
    V[0] = V_app - (E_g/q)-((kB*T)/q)* log(Na/Nv);
    V[N-1] = ((kB*T)/q)*log(Nd/Nc);

   
    //Defining the array of dV's
    double dV[N], max_dV;
    double p[N], n[N];
    for(int i=1;i<N-1; i++){
        p[i] =0;
        n[i]=0;
        dV[i]=0;
    }
    p[0] = Na;
    n[0] = pow(n_i,2)/ Na;
    p[N-1] = pow(n_i,2)/Nd;
    n[N-1] = Nd;

    //Doing a while loop such that it converges
    while(1){  
    
    //Defining the rho matrix with required values
    for(int i=0; i<N; i++){
        if(i< (int)(N)/2){
            rho[i] = q*(-Na+p[i]-n[i]);
        }
        else {
            rho[i] = q*(Nd+p[i]-n[i]);
        }
    }
    //Defining the jacobian matrix for solving J*(dv)= - F
    /*printf("Rho array\n");
    for(int i=0; i<N; i++){
        printf("%e\t", rho[i]);
    }
    printf("\n");*/
    double jacobian_F[N][N];

    for(int i =0; i<N; i++){
        for(int j=0; j<N;j++){
           if(i==j+1 || i== j-1&& i>0){
             jacobian_F[i][j] = 1/pow(dx,2);
            }
            else if(i==j){
                jacobian_F[i][j] = -2/pow(dx,2) - (pow(q,2)/(kB*T* epsi)) * (p[i] + n[i]);
            }
            else jacobian_F[i][j] =0;
            jacobian_F[0][0]=1;
            jacobian_F[N-1][N-1]=1;
        }
    }

    //Defining the Function array
    double F[N];
    for(int i =1; i<N-1; i++){
        F[i]= (V[i-1]-2*V[i]+V[i+1])/pow(dx,2) + rho[i]/epsi;
        F[i]*=(-1);
    }
    // values of boundary conditions
    F[0]=0;
    F[N-1]=0;
   
for (int i = 0; i < N - 1; i++) {
    // Elimination process
    for (int j = i + 1; j < N-1; j++) {
        double factor = jacobian_F[j][i] / jacobian_F[i][i];
        for (int k = i; k < N; k++) {
            jacobian_F[j][k] -= factor * jacobian_F[i][k];
        }
        F[j] -= factor * F[i];
    }
}
 /*printf("F values\n");
    for(int i=0; i<N; i++){
        printf("%e\t", F[i]);
    }
    printf("\n");*/
// Backward substitution
dV[N - 1] = F[N - 1] / jacobian_F[N - 1][N - 1];
for (int i = N - 2; i >= 0; i--) {
    double sum = F[i];
    for (int j = i + 1; j < N; j++) {
        sum -= jacobian_F[i][j] * dV[j];
    }
    dV[i] = sum / jacobian_F[i][i];
}
dV[0]=0;
/*printf("dV values\n");
    for(int i=0; i<N; i++){
        printf("%e\t", dV[i]);
    }
    printf("\n");*/
    // voltage matrix
    for(int i =1; i<N-1;i++){
        V[i]=V[i]+dV[i];
    }

    //Defining the max value of the errors and finding the max value(condition for breaking the while loop)
    max_dV= dV[0];
    for(int i=0; i<N;i++){
        if(dV[i] > max_dV){
            max_dV= dV[i];
        }
    }

    //Carrier Continuity eqn for equillibrium
    for (int i = 1 ; i < N - 1 ; i++) {
      n[i] = Nc*exp((q*V[i]/(kB*T)));
      p[i] = Nv*exp(-(q*V[i] + E_g)/(kB*T));
    }

    if (it == 10000) {
        break;
    }
    it ++;

    /*Section 2: Scharfetter Gummel discretization for carrier continuity*/
/*
    //Defining the recombination function
    double R[N];
    for(int i=0; i<N; i++){
        R[i]= (n[i]*p[i] - pow(n_i,2))/(t_p*(n[i]+n_i)+ t_n*(p[i]+n_i));
        }

    */
   
    }
    printf("Rho array\n");
    for(int i=0; i<N; i++){
        printf("%e\t", rho[i]);
    }
    printf("\n");
    // printf("F values\n");
    //for(int i=0; i<N; i++){
      //  printf("%e\t", F[i]);
    //}
    printf("\n");
    printf("dV values\n");
    for(int i=0; i<N; i++){
        printf("%e\t", dV[i]);
    }
    printf("\n");
for (int i = 0 ; i < N ; i++) {
    printf("%e\t%e\t%e\n",V[i],n[i],p[i]);
  }
    FILE *file_p = fopen("p.txt", "w");
    if (file_p == NULL) {
        printf("Error opening p.txt for writing\n");
        return 1;
    }

    for (int i = 0; i < N;  i++) {
        fprintf(file_p, "%e\n", (p[i]));
    }

    fclose(file_p);

    FILE *file_n = fopen("n.txt", "w");
    if (file_n == NULL) {
        printf("Error opening n.txt for writing\n");
        return 1;
    }

    for (int i = 0; i < N; i++) {
        fprintf(file_n, "%e\n", (n[i]));
    }

    fclose(file_n);
   

    return 0;
}