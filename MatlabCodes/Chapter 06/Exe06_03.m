function MertonModelChFAndExactSolution
clc;clf;close all;

% Arguments for the COS method

tau    = [10];
L      = 8;
N      = 1000;
r      = 0.05;

% Merton model parameters

S0     = 100;
CP     = 'c';
sigma  = 0.15;
muJ    = -0.05;
sigmaJ = 0.3;
xiP    = 0.7;

% Range of strike prices

K      = linspace(20,5*S0,25)'; 

% Analytic expression for option prices

valueExact = MertonCallPrice(CP,S0,K,r,tau,muJ,sigmaJ,sigma,xiP);

% Compute ChF for the Merton model

cf = ChFForMertonModel(r,tau,muJ,sigmaJ,sigma,xiP);

% The COS method

valCOS = CallPutOptionPriceCOSMthd(cf,CP,S0,r,tau,K,N,L);

figure(1)
plot(K,valCOS,'k')
hold on
plot(K,valueExact,'.r')
grid on
xlabel('strike')
ylabel('option value')
legend('COS method','Exact Solution')

function valueExact = MertonCallPrice(CP,S0,K,r,tau,muJ,sigmaJ,sigma,xiP)
X0  = log(S0);

% Term for E(exp(J)-1)

helpExp = exp(muJ + 0.5 * sigmaJ * sigmaJ) - 1.0;
           
% Analytic representation for Merton's option price

muX     = @(n) X0 + (r - xiP * helpExp - 0.5 * sigma * sigma) * tau + n * muJ;
sigmaX  = @(n) sqrt(sigma * sigma + n * sigmaJ * sigmaJ / tau); 
d1      = @(n) (log(S0./K) + (r - xiP * helpExp - 0.5*sigma * sigma ...
         + sigmaX(n)^2.0) * tau + n * muJ) / (sigmaX(n) * sqrt(tau));
d2      = @(n) d1(n) - sigmaX(n) * sqrt(tau);
value_n = @(n) exp(muX(n) + 0.5*sigmaX(n)^2.0*tau)...
          * normcdf(d1(n)) - K .* normcdf(d2(n));
      
% Option value calculation, it is an infinite sum but we truncate at 20 terms

valueExact = value_n(0.0);
kidx = 1:20;
for k = kidx
    valueExact = valueExact+  (xiP * tau).^k * value_n(k) / factorial(k);
end
valueExact = valueExact * exp(-r*tau) * exp(-xiP * tau);

if CP == 'p'
    valueExact = valueExact - S0 + K * exp(-r*tau);
end

function cf = ChFForMertonModel(r,tau,muJ,sigmaJ,sigma,xiP)

% Term for E(exp(J)-1)

i = complex(0,1);
helpExp = exp(muJ + 0.5 * sigmaJ * sigmaJ) - 1.0;
  
% Characteristic function for Merton's model    

cf = @(u) exp(i * u .* (r - xiP * helpExp - 0.5 * sigma * sigma) *tau...
        - 0.5 * sigma * sigma * u.^2 * tau + xiP * tau .* ...
        (exp(i * u * muJ - 0.5 * sigmaJ * sigmaJ * u.^2)-1.0));

function value = CallPutOptionPriceCOSMthd(cf,CP,S0,r,tau,K,N,L)
i = complex(0,1);


% cf   - Characteristic function, in the book denoted as \varphi
% CP   - C for call and P for put
% S0   - Initial stock price
% r    - Interest rate (constant)
% tau  - Time to maturity
% K    - Vector of strike prices
% N    - Number of expansion terms
% L    - Size of truncation domain (typ.:L=8 or L=10)

x0 = log(S0 ./ K);   

% Truncation domain

a = 0 - L * sqrt(tau); 
b = 0 + L * sqrt(tau);

k = 0:N-1;              % Row vector, index for expansion terms
u = k * pi / (b - a);   % ChF arguments

H_k = CallPutCoefficients(CP,a,b,k);
temp    = (cf(u) .* H_k).';
temp(1) = 0.5 * temp(1);      % Multiply the first element by 1/2

mat = exp(i * (x0 - a) * u);  % Matrix-vector manipulations

% Final output

value = exp(-r * tau) * K .* real(mat * temp);

% Coefficients H_k for the COS method

function H_k = CallPutCoefficients(CP,a,b,k)
    if lower(CP) == 'c' || CP == 1
        c = 0;
        d = b;
        [Chi_k,Psi_k] = Chi_Psi(a,b,c,d,k);
         if a < b && b < 0.0
            H_k = zeros([length(k),1]);
         else
            H_k = 2.0 / (b - a) * (Chi_k - Psi_k);
         end
    elseif lower(CP) == 'p' || CP == -1
        c = a;
        d = 0.0;
        [Chi_k,Psi_k]  = Chi_Psi(a,b,c,d,k);
         H_k = 2.0 / (b - a) * (- Chi_k + Psi_k);       
    end

function [chi_k,psi_k] = Chi_Psi(a,b,c,d,k)
    psi_k        = sin(k * pi * (d - a) / (b - a)) - sin(k * pi * (c - a)/(b - a));
    psi_k(2:end) = psi_k(2:end) * (b - a) ./ (k(2:end) * pi);
    psi_k(1)     = d - c;
    
    chi_k = 1.0 ./ (1.0 + (k * pi / (b - a)).^2); 
    expr1 = cos(k * pi * (d - a)/(b - a)) * exp(d)  - cos(k * pi... 
                  * (c - a) / (b - a)) * exp(c);
    expr2 = k * pi / (b - a) .* sin(k * pi * ...
                        (d - a) / (b - a))   - k * pi / (b - a) .* sin(k... 
                        * pi * (c - a) / (b - a)) * exp(c);
    chi_k = chi_k .* (expr1 + expr2);
    
% Closed-form expression of European call/put option with Black-Scholes formula

function value=BS_Call_Option_Price(CP,S_0,K,sigma,tau,r)

% Black-Scholes call option price

d1    = (log(S_0 ./ K) + (r + 0.5 * sigma^2) * tau) / (sigma * sqrt(tau));
d2    = d1 - sigma * sqrt(tau);
if lower(CP) == 'c' || lower(CP) == 1
    value =normcdf(d1) * S_0 - normcdf(d2) .* K * exp(-r * tau);
elseif lower(CP) == 'p' || lower(CP) == -1
    value =normcdf(-d2) .* K*exp(-r*tau) - normcdf(-d1)*S_0;
end
