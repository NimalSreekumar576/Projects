%% Buck converter design and buck vs LDO comparison
Vin = 12; Vout = 5; Iout = 1; fsw = 500e3;
D   = Vout/Vin;
dIL = 0.3*Iout;
L   = Vout*(1-D)/(fsw*dIL);  L = 22e-6;     % chosen standard value
dIL_act = Vout*(1-D)/(fsw*L);
C   = 22e-6;
fprintf('D=%.3f, L=%.1f uH, ripple=%.3f A\n', D, L*1e6, dIL_act);

%% Efficiency vs load (simple loss model)
I = linspace(0.05, 1.5, 200);
Rhs = 0.10; Rls = 0.05; DCR = 0.03;          % ohms
tsw = 10e-9;                                  % rise+fall time
Pcond = I.^2 .* (D*Rhs + (1-D)*Rls + DCR);
Psw   = 0.5*Vin.*I*tsw*fsw;
Pfix  = 0.02;                                 % gate drive + quiescent
Pout  = Vout*I;
eff_buck = Pout ./ (Pout + Pcond + Psw + Pfix) * 100;
eff_ldo  = Pout ./ (Vin*(I + 0.001)) * 100;   % 1 mA Iq

figure; plot(I, eff_buck, 'LineWidth', 2); hold on;
plot(I, eff_ldo, '--', 'LineWidth', 2); grid on;
xlabel('Load current (A)'); ylabel('Efficiency (%)');
legend('Buck (12V to 5V)', 'LDO (12V to 5V)', 'Location', 'east');
title('Buck vs LDO efficiency');

%% Control-to-output transfer function (voltage mode, ideal)
R = Vout/Iout;
s = tf('s');
Gvd = Vin / (1 + s*L/R + s^2*L*C);
figure; bode(Gvd); grid on; title('Buck control-to-output (open loop)');
f0 = 1/(2*pi*sqrt(L*C));
fprintf('LC resonant frequency = %.1f kHz\n', f0/1e3);
