function splitstr = strsplit(str,delim)

splitstr = regexp(str,regexptranslate('escape',delim),'split');

end