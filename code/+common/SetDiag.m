function mat = SetDiag(mat,diagVal)
    % assign values to the diagonal of a matrix
    validateattributes(mat,{'numeric'},{'square'});
    validateattributes(diagVal,{'numeric'},{'vector','nonempty'});    
    switch numel(diagVal)
        case 1
        case size(mat,1)
        otherwise
            error('SetDiag:sizeMismatch','Desired diagonal values must be scalar or match size of input matrix.');
    end
    diagInds = logical ( eye ( size ( mat ) ) ) ;
    mat ( diagInds ) = diagVal ;           
end