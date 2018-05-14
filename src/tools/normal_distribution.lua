-----
-- Normal Distribution
--
-- Dependencies:
-- @classmod NormalDistribution

NormalDistribution = class()

--- create a random variable.
--
-- @number mean
-- @number variance
--
-- @class function
-- @name NormalDistribution
-- @usage local dist = NormalDistribution(2,4)
function NormalDistribution:_init (mean, variance)

    if (type(mean) ~= "number") then
        error("parameter 'mean' need to be a number")
    end
    if (type(variance) ~= "number") then
        error("parameter 'variance' need to be a number")
    end

    self.mean = mean
    self.variance = variance
end

function NormalDistribution:getProbability(value)
    return math.exp(-(math.pow(value-self.mean, 2) / (2 * self.variance))) / math.sqrt(2 * self.variance * math.pi)
end

function NormalDistribution:getTexFunction()
    return string.format("exp(-1 * ((x - %f)^2) / (2 * (%f^2)))  / (sqrt(2 * (%f^2) * pi))", self.mean, self.variance, self.variance)
end