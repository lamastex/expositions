function INT = times(INT1,INT2)
% vpi/times: Multiplies two vpi objects, or a product of a numeric var to an vpi
% usage: INT = INT1*INT2;
% usage: INT = times(INT1,INT2);
% 
% arguments: (input)
%  INT1,INT2 - vpi scalars, or any scalar numeric integers
%
% arguments: (output)
%  INT - a vpi that represents the product of INT1.*INT2
%
% Example:
%  m = vpi('112233445566778899001');
%  m.*m
%  ans =
%     12596346303791122097616897242785758798001
%
%  999.*m
%  ans =
%     112121212121212120101999
%
%  m.*10101010101
%  ans =
%     1133671167340067328842759809101
%
%
%  See also: mtimes
%  
% 
%  Author: John D'Errico
%  e-mail: woodchips@rochester.rr.com
%  Release: 1.0
%  Release date: 1/19/09

if nargin ~= 2
  error('2 arguments required. times is a dyadic operator.')
end

nint1 = numel(INT1);
nint2 = numel(INT2);
if (nint1 == 1) && (nint2 == 1)
  % a pair of scalar elements to multiply

  % which pure decimal shifts will we
  % accelerate as a simple shift?
  shifts = {10 100 1000 10000 1e5 1e6 1e7 1e8};

  % were either of the numbers 0 or 1?
  if (INT1 == 0) || (INT2 == 0)
    INT = vpi(0);
    return
  elseif INT1 == 1
    INT = vpi(INT2);
    return
  elseif INT2 == 1
    INT = vpi(INT1);
    return
  end

  % are both INT1 and INT2 vpi objects?
  % numflag identifies the case where
  % the first element is a double
  numflag = false;
  if ~isa(INT1,'vpi')
    % if it is large enough, make it a vpi
    if abs(INT1) > shifts{end}
      % just convert it to an vpi object
      INT1 = vpi(INT1);
    else
      numflag = true;
    end
  end
  if ~isa(INT2,'vpi')
    % swap INT1 and INT2, since INT1 must be an vpi
    % to have gotten in here.
    [INT2,INT1] = deal(INT1,INT2);
    if abs(INT1) > shifts{end}
      % convert to an vpi object if too big
      INT1 = vpi(INT1);
    else
      numflag = true;
    end
  end

  % Is INT1 a real number, or a floating point integer?
  if numflag && rem(INT1,1) ~= 0
    % INT1 is a true float
    warning('Multiplication of a vpi with a non-integer variable, fixed to an integer')
    INT1 = vpi(fix(INT1));
  end
  
  % both are vpi numbers, or only the second.
  % which is it?
  if numflag
    % INT1 is a pure numeric. make sure it is a double.
    S = INT2.sign*(2*(INT1>=0)-1);
    INT1 = abs(double(INT1));

    INT = INT2;
    INT.sign = S;
    
    % do the multiply, INT1 is scalar numeric and non-negative
    % check for some special cases.
    switch INT1
      case 0
        INT.digits = 0;
        INT.sign = 1;
      case 1
        % a no-op at this point

      case shifts
        % decimal digit shift. how many digits?
        nshift = find(INT1==cell2mat(shifts));
        INT.digits = [zeros(1,nshift),INT.digits];

      otherwise
        % a general scalar in INT1
        digits = INT1*INT.digits;
        
        % any necessary carries
        carryflag = true;
        while carryflag
          % are there any digits that need a carry?
          K = find((digits<0) | (digits>9));
          if isempty(K)
            carryflag = false;
          else
            % there was at least one carry.
            olddigits = digits(K);
            
            % mod will insure the new digit
            % lies in [0,9].
            newdigits = mod(digits(K),10);
            
            % stuff into place
            digits(K) = newdigits;
            
            % this will be an integer result:
            carry = (olddigits - newdigits)/10;
            
            % will it force us to add another digit
            % to INT?
            if K(end) == numel(digits)
              % do so
              digits(end+1) = 0;
            end
            
            % add in the carried digits. There may
            % be a few new carries created by this
            % operation. The while loop will catch
            % them.
            digits(K+1) = digits(K+1) + carry;
          end
        end
        % stuff the digits vector back into INT
        INT.digits = digits;
        
    end % switch INT1
    
  else
    % a product of two VPI numbers (variable precision integers)
    INT = INT1;
    INT.sign = INT1.sign*INT2.sign;

    % how long are the pieces?
    n1 = find(INT1.digits,1,'last');
    n2 = find(INT2.digits,1,'last');

    digits1 = INT1.digits(1:n1);
    INT.digits = conv(INT1.digits,INT2.digits);

    % now do any necessary carries. Mothing will
    % have gotten too large, since we never had
    % more than 9*9 = 81 to add in.
    digits = INT.digits;
    carryflag = true;
    while carryflag
      % are there any digits that need a carry?
      K = find((digits<0) | (digits>9));
      if isempty(K)
        carryflag = false;
      else
        % there was at least one carry.
        olddigits = digits(K);
        
        % mod will insure the new digit
        % lies in [0,9].
        newdigits = mod(digits(K),10);
        
        % stuff into place
        digits(K) = newdigits;
        
        % this will be an integer result:
        carry = (olddigits - newdigits)/10;
        
        % will it force us to add another digit
        % to INT?
        if K(end) == numel(digits)
          % do so
          digits(end+1) = 0;
        end
        
        % add in the carried digits. There may
        % be a few new carries created by this
        % operation. The while loop will catch
        % them.
        digits(K+1) = digits(K+1) + carry;
      end
    end
    % stuff the digits vector back into INT
    INT.digits = digits;
  end
  
elseif (nint1 == 0) || (nint2 == 0)
  % empty propagates
  INT = [];
  return
elseif (nint1 == 1) && (nint2 > 1)
  % scalar expansion for INT1
  INT = vpi(INT2);
  for i = 1:nint2
    INT(i) = INT1.*INT2(i);
  end
elseif (nint1 > 1) && (nint2 == 1) 
  % scalar expansion for INT2
  INT = vpi(INT1);
  for i = 1:nint1
    INT(i) = INT1(i).*INT2;
  end
else
  % must be two arrays
  
  % do they conform for multiplication?
  if ~isequal(size(INT1),size(INT2))
    error('The two arrays do not conform in size for elementwise multiplication')
  end
  
  % do the scalar multiplies
  INT = vpi(INT2);
  for i = 1:nint1
    INT(i) = INT1(i).*INT2(i);
  end
end




