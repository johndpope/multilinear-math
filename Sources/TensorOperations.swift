//
//  TensorOperations.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation


// Operations on a single tensor

/// sum tensor over the given modes
/// - Returns: a tensor with only the modes that were not summed over
public func sum(tensor: Tensor<Float>, overModes: [Int]) -> Tensor<Float> {
    let remainingModes = tensor.modeArray.removeValues(overModes)
    var outputData = [Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)]
    
    tensor.performForOuterModes(remainingModes, outputData: &outputData,
                                calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
                                    let sum = vectorSummation(sourceData[slice: currentIndex].values)
                                    return [Tensor<Float>(scalar: sum)]
                                }),
                                writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
                                    outputData[0][slice: outerIndex] = inputData[0]
                                }))
    
    return outputData[0]
}

/// Normalize the elements of a tensor over the given modes.
/// - Returns:
/// `normalizedTensor`: <br> Normalized version of the given tensor, the elements along the given modes together have mean zero and a standard devation of one <br>
/// `meanTensor`: <br> Mean of the given tensor, itself a tensor with only the modes that were not normalized over <br>
/// `deviationTensor`: <br> Standard deviation of the given tensor, itself a tensor with only the modes that were not normalized over
//public func normalize(tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
//    
//    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
//    
//    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
//    
//    var normalizedTensor = Tensor<Float>(withPropertiesOf: tensor)
//    var meanTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
//    var deviationTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
//    
//    tensor.perform(outerModes: remainingModes, action: { (currentIndex, outerIndex) in
//        let normalizationSlice = tensor[slice: currentIndex]
//        let normalizedVector = vectorNormalization(normalizationSlice.values)
//        normalizedTensor[slice: currentIndex] = Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector)
//        deviationTensor[slice: outerIndex] = Tensor<Float>(scalar: normalizedVector.standardDeviation)
//        meanTensor[slice: outerIndex] = Tensor<Float>(scalar: normalizedVector.mean)
//    })
//    
//    return (normalizedTensor, meanTensor, deviationTensor)
//}

/// Normalize the elements of a tensor over the given modes.
/// - Returns:
/// `normalizedTensor`: <br> Normalized version of the given tensor, the elements along the given modes together have mean zero and a standard devation of one <br>
/// `meanTensor`: <br> Mean of the given tensor, itself a tensor with only the modes that were not normalized over <br>
/// `deviationTensor`: <br> Standard deviation of the given tensor, itself a tensor with only the modes that were not normalized over
public func normalize(tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
    
    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
    
    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
    
    let normalizedTensor = Tensor<Float>(withPropertiesOf: tensor)
    let meanTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    let deviationTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    var outputData = [normalizedTensor, meanTensor, deviationTensor]
    
    tensor.performForOuterModes(remainingModes, outputData: &outputData,
                                calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
                                    let normalizationSlice = sourceData[slice: currentIndex]
                                    let normalizedVector = vectorNormalization(normalizationSlice.values)
                                    return [Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector),
                                        Tensor<Float>(scalar: normalizedVector.mean),
                                        Tensor<Float>(scalar: normalizedVector.standardDeviation)]
                                }),
                                writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
                                    outputData[0][slice: currentIndex] = inputData[0]
                                    outputData[1][slice: outerIndex] = inputData[1]
                                    outputData[2][slice: outerIndex] = inputData[2]
                                }))
    
    return (outputData[0], outputData[1], outputData[2])
}

/// Normalize the elements of a tensor over the given modes with fixed mean and standard deviation

public func normalize(tensor: Tensor<Float>, overModes: [Int], withMean mean: Tensor<Float>, deviation: Tensor<Float>) -> Tensor<Float> {
    
    let commonModes = tensor.modeArray.removeValues(overModes)
    let deviationInverse = 1/deviation
    
    let offsetTensor = substract(a: tensor, commonModesA: commonModes, outerModesA: overModes, b: mean, commonModesB: mean.modeArray, outerModesB: [])
    let scaledTensor = multiplyElementwise(a: offsetTensor, commonModesA: commonModes, outerModesA: overModes, b: deviationInverse, commonModesB: deviationInverse.modeArray, outerModesB: [])
    
    return scaledTensor
}

/// Transform a tensor by scaling it and then adding an offset
/// - Parameter tensor: The tensor to be transformed
/// - Parameter overModes: These modes will be transformed
/// - Parameter scale: A tensor with all the scale factors, itself a tensor with only the modes that will not be transformed over
/// - Parameter offset: A tensor with all the offsets, itself a tensor with only the modes that will not be transformed over
//public func transform(tensor: Tensor<Float>, overModes: [Int], scale: Tensor<Float>, offset: Tensor<Float>) -> Tensor<Float> {
//    
//    let commonModes = tensor.modeArray.removeValues(overModes)
//    
//    let scaledTensor = multiplyElementwise(a: tensor, commonModesA: commonModes, outerModesA: overModes, b: scale, commonModesB: scale.modeArray)
//    let offsetTensor = substract(a: scaledTensor, commonModesA: commonModes, outerModesA: overModes, b: offset, commonModesB: offset.modeArray)
//    
//    return offsetTensor
//}

/// Inverse two modes with same size of a tensor
public func inverse(tensor: Tensor<Float>, rowMode: Int, columnMode: Int) -> Tensor<Float> {
    assert(rowMode != columnMode, "rowMode and columnMode cannot be the same")
    let remainingModes = tensor.modeArray.filter({$0 != rowMode && $0 != columnMode})
    
    let rows = tensor.modeSizes[rowMode]
    let columns = tensor.modeSizes[columnMode]
    assert(rows == columns, "mode \(rowMode) and \(columnMode) have not the same size")
    
    var inverseTensor = [Tensor<Float>(withPropertiesOf: tensor)]
    
    tensor.performForOuterModes(remainingModes, outputData: &inverseTensor, calculate: ({ (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
        let inverseSlice = sourceData[slice: currentIndex]
        let inverseVector = matrixInverse(inverseSlice.values, size: MatrixSize(rows: rows, columns: columns))
        return [Tensor<Float>(modeSizes: [rows, columns], values: inverseVector)]
    }), writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
        outputData[0][slice: currentIndex] = inputData[0]
    }))
    
    return inverseTensor[0]
}

/// Exponential of every element of the tensor
public func exp(tensor: Tensor<Float>) -> Tensor<Float> {
    let exp = Tensor<Float>(withPropertiesOf: tensor, values: vectorExponential(tensor.values))
    return exp
}

/// Natural logarithm of every element of the tensor
public func log(tensor: Tensor<Float>) -> Tensor<Float> {
    let log = Tensor<Float>(withPropertiesOf: tensor, values: vectorLogarithm(tensor.values))
    return log
}


// Operations combining two tensors

public func concatenate(a a: Tensor<Float>, b: Tensor<Float>, alongMode: Int) -> Tensor<Float> {
    var newModeSizes: [Int]
    var sliceA: [DataSliceSubscript]
    var sliceB: [DataSliceSubscript]
    
    if(a.modeCount == b.modeCount) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = Range(start: a.modeSizes[alongMode], distance: b.modeSizes[alongMode])
        
        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + b.modeSizes[alongMode]
    } else if(a.modeCount == b.modeCount+1) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = Range(start: a.modeSizes[alongMode], distance: 1)
        
        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else if(a.modeCount == b.modeCount-1) {
        var aModeSizes = a.modeSizes
        aModeSizes.insert(1, atIndex: alongMode)
        sliceA = aModeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = Range(start: 1, distance: b.modeSizes[alongMode])
        newModeSizes = b.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else {
        print("tensors with mode sizes \(a.modeSizes) and \(b.modeSizes) cannot be concatenated along mode \(alongMode)")
        return a
    }
    
    var concatTensor = Tensor<Float>(modeSizes: newModeSizes, repeatedValue: 0)
    concatTensor[slice: sliceA] = a
    concatTensor[slice: sliceB] = b
    
    return concatTensor
}

public func add(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var sum = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerModesA, with: b, forOuterModes: outerModesB, outputData: &sum,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let sumVector = vectorAddition(vectorA: a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: sumVector)]
    }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
    }))

    return sum[0]
}

public func substract(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var difference = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerModesA, with: b, forOuterModes: outerModesB, outputData: &difference,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let differenceVector = vectorSubtraction(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: differenceVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return difference[0]
}

public func multiplyElementwise(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var product = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerModesA, with: b, forOuterModes: outerModesB, outputData: &product,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let productVector = vectorElementWiseMultiplication(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: productVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return product[0]
}

public func divide(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var quotient = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerModesA, with: b, forOuterModes: outerModesB, outputData: &quotient,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let quotientVector = vectorDivision(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: quotientVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return quotient[0]
}
