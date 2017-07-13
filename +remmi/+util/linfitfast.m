function par = linfitfast(x,y,w)

M = [x, ones(size(x))];
par = (M'*diag(w)*M)\(M'*diag(w)*y);