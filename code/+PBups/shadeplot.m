% SHADEPLOT plot shading
%
%=INPUT
%   x
%       dependent data
%
%   y1
%       the first trace of the y data
%
%   y2
%       the second trace of the y data
%
%=OPTIONAL INPUT
%
%   Alpha
%       A scalar in the range [0,1] specifying the transparency. 0 is
%       transparent.
%
%   Color
%       A three-element array with elements between 0 and 1 specifying the
%       color as red, green, and blue intensities
%
%   error_type
%       A char array specifying whether y1 and y2 represent the lower and
%       upper bounds of the confidence interval ('CI') or whether y1 is the
%       mean and y2 is the offset from the mean. 
function varargout = shadeplot(x,y1,y2,varargin)
input_parser = inputParser;
addParameter(input_parser, 'Alpha', 0.2, ...
    @(x) validateattributes(x, {'numeric'}, {'scalar', '>=', 0, '<=', 1}))
addParameter(input_parser, 'Color', [0,0,0], ...
    @(x) validateattributes(x, {'numeric'}, {'numel', 3, '>=', 0, '<=', 1}))
addParameter(input_parser, 'error_type', 'CI', @(x) isstring(x) || ischar(x))
parse(input_parser, varargin{:});
for parameters = fields(input_parser.Results)'; param = parameters{:};        
    if isstring(input_parser.Results.(param)); param = char(param); end
    eval([param ' = input_parser.Results.' param ';']);
end
if strcmpi(error_type, 'CI')
    if nanmean(nanmean(y1)) < nanmean(nanmean(y2))
        y_lower = y1;
        y_upper = y2;
    else
        y_lower = y2;
        y_upper = y1;
    end
else
    y_lower = y1-y2;
    y_upper = y1+y2;
end

Y=[y_upper(:), y_lower(:)-y_upper(:)];
h = area(x,Y);
set(h(2),'EdgeColor','none','FaceColor', Color, 'FaceAlpha', Alpha);
set(h(1),'EdgeColor','none','FaceColor', 'none');

if nargout == 1
    varargout{1} = h(2);
end