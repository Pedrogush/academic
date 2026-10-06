hMod = comm.QPSKModulator;
hRCTxFilter = comm.RaisedCosineTransmitFilter(...
'Shape','Normal', ...
'RolloffFactor',0.5, ...
'FilterSpanInSymbols',Rup, ...
'OutputSamplesPerSymbol',Rup);
Rup = 64; % upsampling rate
%número de bit = ndBit
ndBit=1000;
data = randi([0 3],1000,1);
modData = step(hMod, data);
hScope = comm.ConstellationDiagram('SamplesPerSymbol',Rup);
txSig = step(hRCTxFilter,modData);
gain = 1/max(hRCTxFilter.coeffs.Numerator);
txSig = gain*step(hRCTxFilter,modData);
%rcv = awgn(txSig,10,'measured');
%step(hScope,rcv)
%hScope.ShowReferenceConstellation = false;
rcv = awgn(txSig,9,'measured');
step(hScope,rcv)