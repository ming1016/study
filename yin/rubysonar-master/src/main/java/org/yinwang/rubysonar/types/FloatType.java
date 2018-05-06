package org.yinwang.rubysonar.types;


import org.yinwang.rubysonar.Analyzer;


public class FloatType extends Type {
    public double upper = Double.POSITIVE_INFINITY;
    public double lower = Double.NEGATIVE_INFINITY;


    public FloatType() {
    }


    public FloatType(double value) {
        this.lower = this.upper = value;
    }


    public FloatType(double lower, double upper) {
        this.lower = lower;
        this.upper = upper;
    }


    public FloatType(FloatType other) {
        this.lower = other.lower;
        this.upper = other.upper;
    }


    public static FloatType add(FloatType a, FloatType b) {
        double lower = a.lower + b.lower;
        double upper = a.upper + b.upper;
        return new FloatType(lower, upper);
    }


    public static FloatType sub(FloatType a, FloatType b) {
        double lower = a.lower - b.upper;
        double upper = a.upper - b.lower;
        return new FloatType(lower, upper);
    }


    public FloatType negate() {
        return new FloatType(-upper, -lower);
    }


    public static FloatType mul(FloatType a, FloatType b) {
        double lower = a.lower * b.lower;
        double upper = a.upper * b.upper;
        return new FloatType(lower, upper);
    }


    public static FloatType div(FloatType a, FloatType b) {
        double lower = a.lower / b.upper;
        double upper = a.upper / b.lower;
        return new FloatType(lower, upper);
    }


    public boolean lt(FloatType other) {
        return isFeasible() && this.upper < other.lower;
    }


    public boolean lt(double other) {
        return isFeasible() && this.upper < other;
    }


    public boolean gt(FloatType other) {
        return isFeasible() && this.lower > other.upper;
    }


    public boolean gt(double other) {
        return isFeasible() && this.lower > other;
    }


    public boolean eq(FloatType other) {
        return isActualValue() && other.isActualValue() && this.lower == other.lower;
    }


    public boolean isZero() {
        return isActualValue() && lower == 0;
    }


    public boolean isUpperBounded() {
        return upper != Double.POSITIVE_INFINITY;
    }


    public void setUpperUnbounded(boolean upperUnbounded) {
        this.upper = Double.POSITIVE_INFINITY;
    }


    public boolean isLowerBounded() {
        return lower != Double.NEGATIVE_INFINITY;
    }


    public void setLowerUnbounded(boolean lowerUnbounded) {
        this.lower = Double.NEGATIVE_INFINITY;
    }


    public boolean isActualValue() {
        return lower == upper;
    }


    public boolean isFeasible() {
        return lower <= upper;
    }


    public void setUpper(double upper) {
        this.upper = upper;
    }


    public void setLower(double lower) {
        this.lower = lower;
    }


    public void setActual(double actual) {
        this.lower = this.upper = actual;
    }


//    @Override
//    public boolean equals(Object other) {
//        return other instanceof FloatType;
//    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        StringBuilder sb = new StringBuilder("float");

        if (Analyzer.self.hasOption("debug")) {
            if (lower == upper) {
                sb.append("(" + lower + ")");
            } else if (isLowerBounded() || isUpperBounded()) {
                sb.append("[");
                if (isLowerBounded()) {
                    sb.append(lower);
                } else {
                    sb.append("-∞");
                }
                sb.append("..");
                if (isUpperBounded()) {
                    sb.append(upper);
                } else {
                    sb.append("+∞");
                }
                sb.append("]");
            }
        }

        return sb.toString();
    }

}
