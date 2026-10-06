function A = can(vect)
    for linha=1:length(vect)
        for coluna=1:length(vect)
            if linha<length(vect)
            if coluna~=linha+1
                A(linha,coluna) = 0;
            end
            end
            if linha+1==coluna
            if linha<length(vect)
                A(linha,coluna)        = 1;
            end
            end
            if linha==length(vect)
                A(linha,coluna) = vect(coluna);
            end
        end
    end
end