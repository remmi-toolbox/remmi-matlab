function bm = bmatAgilent(pp)

% for now, just use the bmatrix provided by procpar
bm = [pp.bvalrr pp.bvalpp pp.bvalss -pp.bvalrp -pp.bvalsp pp.bvalrs]; 
bm(:,7) = 1000;