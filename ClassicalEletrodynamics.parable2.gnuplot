set table "ClassicalEletrodynamics.parable2.table"; set format "%.5f"
set format "%.7e";; set samples 1000; set dummy x; plot [x=0:40] 2*1/x*besy1(x)-besy0(x);
