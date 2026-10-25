%-- Log from MATLAB Model.
%read Matlab input and write it on a file
Input_Vec = round(inputSignal.Data(1:3000).*2^13);
file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\InputSignal_Vec.txt','w');
for i = 1:length(Input_Vec)
    fprintf(file_Buf,'%d\r\n',Input_Vec(i));
end
fclose(file_Buf);


Input_Vec = round(inputRefSignal.Data(1:3000).*2^13);
file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\InputRefSignal_Vec.txt','w');
for i = 1:length(Input_Vec)
    fprintf(file_Buf,'%d\r\n',Input_Vec(i));
end
fclose(file_Buf);


%read Matlab output Amplitude and write it on file
Output_Vec1 = round(Amplitude.Data(1:3000).*2^13);
file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Matlab_Amplitude_Vec.txt','w');
for i = 1:length(Output_Vec1)
    fprintf(file_Buf,'%d\r\n',Output_Vec1(i));
end
fclose(file_Buf);


%read Matlab output Phase Difference and write it on file
Output_Vec2 = round(PhaseDifference.Data(1:3000).*2^13);
file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Matlab_PhaseDiff_Vec.txt','w');
for i = 1:length(Output_Vec2)
    fprintf(file_Buf,'%d\r\n',Output_Vec2(i));
end
fclose(file_Buf);



%%

%-- Plot Matlab and VHDL Amplitude

file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Matlab_Amplitude_Vec.txt');
Output_Vec_Sig = fscanf(file_Buf , '%d');
fclose(file_Buf);

file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Vhdl_Amplitude_Vec.txt');
Output_Vec_Sig_HDL = fscanf(file_Buf , '%d');
fclose(file_Buf);

plot(Output_Vec_Sig(1:800)./2^13)
hold
plot(Output_Vec_Sig_HDL(1:800)./2^13, 'ro')
legend('MATLAB - Fixed-Point','VHDL - Fixed-Point')

%%

%-- Plot Matlab and VHDL Phase Difference

file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Matlab_PhaseDiff_Vec.txt');
Output_Vec_Sig = fscanf(file_Buf , '%d');
fclose(file_Buf);

file_Buf = fopen('C:\Users\Hasan\My_Projects\DSP\IQ_Demodulator\matlab\Vhdl_PhaseDiff_Vec.txt');
Output_Vec_Sig_HDL = fscanf(file_Buf , '%d');
fclose(file_Buf);

plot(Output_Vec_Sig(1:800)./2^13)
hold
plot(Output_Vec_Sig_HDL(1:800)./2^11, 'ro')
legend('MATLAB - Fixed-Point','VHDL - Fixed-Point')


