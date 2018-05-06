package org.yinwang.rubysonar.types;


import org.yinwang.rubysonar.Analyzer;

import java.math.BigInteger;


public class IntType extends Type {

    public BigInteger lower;
    public BigInteger upper;
    public boolean lowerBounded;
    public boolean upperBounded;


    public IntType() {
        this.lower = BigInteger.ZERO;
        this.upper = BigInteger.ZERO;
        lowerBounded = upperBounded = false;
    }


    public IntType(BigInteger lower, BigInteger upper, boolean lowerBounded, boolean upperBounded) {
        this.lower = lower;
        this.upper = upper;
        this.lowerBounded = lowerBounded;
        this.upperBounded = upperBounded;
    }


    public IntType(BigInteger value) {
        this.lower = this.upper = value;
        lowerBounded = upperBounded = true;
    }


    public IntType(BigInteger lower, BigInteger upper) {
        this.lower = lower;
        this.upper = upper;
        lowerBounded = upperBounded = true;
    }


    public IntType(IntType other) {
        this.lower = other.lower;
        this.upper = other.upper;
        this.lowerBounded = other.lowerBounded;
        this.upperBounded = other.upperBounded;
    }


    public static IntType add(IntType a, IntType b) {
        BigInteger lower = a.lower.add(b.lower);
        BigInteger upper = a.upper.add(b.upper);
        boolean lowerBounded = a.lowerBounded && b.lowerBounded;
        boolean upperBounded = a.upperBounded && b.upperBounded;
        return new IntType(lower, upper, lowerBounded, upperBounded);
    }


    public static IntType sub(IntType a, IntType b) {
        BigInteger lower = a.lower.subtract(b.upper);
        BigInteger upper = a.upper.subtract(b.lower);
        boolean lowerBounded = a.lowerBounded && b.lowerBounded;
        boolean upperBounded = a.upperBounded && b.upperBounded;
        return new IntType(lower, upper, lowerBounded, upperBounded);
    }


    public IntType negate() {
        return new IntType(upper.negate(), lower.negate());
    }


    public static IntType mul(IntType a, IntType b) {
        BigInteger lower = a.lower.multiply(b.lower);
        BigInteger upper = a.upper.multiply(b.upper);
        boolean lowerBounded = a.lowerBounded && b.lowerBounded;
        boolean upperBounded = a.upperBounded && b.upperBounded;
        return new IntType(lower, upper, lowerBounded, upperBounded);
    }


    public static IntType div(IntType a, IntType b) {
        boolean lowerBounded = a.lowerBounded && b.upperBounded;
        boolean upperBounded = a.upperBounded && b.lowerBounded;

        BigInteger lower = BigInteger.ZERO;
        if (lowerBounded && !b.upper.equals(BigInteger.ZERO)) {
            lower = a.lower.divide(b.upper);
        } else {
            lowerBounded = false;
        }

        BigInteger upper = BigInteger.ZERO;
        if (upperBounded && !b.lower.equals(BigInteger.ZERO)) {
            upper = a.upper.divide(b.lower);
        } else {
            upperBounded = false;
        }

        return new IntType(lower, upper, lowerBounded, upperBounded);
    }


    public boolean lt(IntType other) {
        return this.isUpperBounded() &&
                other.isLowerBounded() &&
                this.upper.compareTo(other.lower) < 0;
    }


    public boolean lt(BigInteger other) {
        return this.isUpperBounded() && this.upper.compareTo(other) < 0;
    }


    public boolean gt(IntType other) {
        return this.isLowerBounded() &&
                other.isUpperBounded() &&
                this.lower.compareTo(other.upper) > 0;
    }


    public boolean gt(BigInteger other) {
        return this.isLowerBounded() && this.lower.compareTo(other) > 0;
    }


    public boolean eq(IntType other) {
        return isActualValue() && other.isActualValue() &&
                this.lower.equals(other.lower);
    }


    public boolean isZero() {
        return isActualValue() && lower.equals(BigInteger.ZERO);
    }


    public boolean isUpperBounded() {
        return upperBounded;
    }


    public boolean isLowerBounded() {
        return lowerBounded;
    }


    public boolean isActualValue() {
        return isLowerBounded() && isUpperBounded() && lower.equals(upper);
    }


    public boolean isFeasible() {
        return lower.compareTo(upper) <= 0;
    }


    public void setLower(BigInteger lower) {
        this.lower = lower;
        this.lowerBounded = true;
    }


    public void setUpper(BigInteger upper) {
        this.upper = upper;
        this.upperBounded = true;
    }


//    @Override
//    public boolean equals(Object other) {
//        return other instanceof IntType;
//    }


    @Override
    protected String printType(Type.CyclicTypeRecorder ctr) {
        StringBuilder sb = new StringBuilder("int");

        if (Analyzer.self.hasOption("debug")) {
            if (isActualValue() && lower.equals(upper)) {
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
