function longSym = chararToSym(number)
    mustBeA(number, 'char');
    longSym = sym(0);

    for l = 1:length(number)
        digit = str2double(number(l));
        longSym = longSym + (sym(digit) * sym(10^(length(number)-l)));
    end

end