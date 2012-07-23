//
//  ZGeometry_utils.h
//
//  Created by Lukas Zeller on 2010/07/29.
//  Copyright (c) 2010-2011 by Lukas Zeller. All rights reserved.
//

#include <math.h>

#import <UIKit/UIKit.h>

CGFloat lengthOfVector(CGSize vector);
CGSize normalizeVector(CGSize vector);
CGPoint addPointAndVector(CGPoint point, CGSize vector);
CGSize addVectors(CGSize vector1, CGSize vector2);
CGSize vectorFromFirstToSecondPoint(CGPoint first, CGPoint second);
CGSize vectorFromFirstToSecondVector(CGSize first, CGSize second);
CGFloat distanceBetweenPoints (CGPoint first, CGPoint second);
CGPoint movePointAlongVector(CGPoint point, CGSize vector, CGFloat factor, CGFloat orthogonalFactor);
CGSize scaleVector(CGSize vector, CGFloat factor);
CGSize pointToSize(CGPoint point);
CGPoint sizeToPoint(CGSize size);

CGFloat normalizeAngle(CGFloat aAngle);
