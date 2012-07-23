//
//  ZGeometry_utils.m
//
//  Created by Lukas Zeller on 2010/07/29.
//  Copyright (c) 2010-2011 by Lukas Zeller. All rights reserved.
//

#import "ZGeometry_utils.h"


CGFloat lengthOfVector(CGSize vector)
{
  return sqrt(vector.width*vector.width + vector.height*vector.height);
};



CGSize normalizeVector(CGSize vector)
{
  CGSize result;
  CGFloat len = lengthOfVector(vector);
  if (len<=0)
    return CGSizeZero;
  result.width = vector.width/len;
  result.height = vector.height/len;
  return result;
}


CGPoint addPointAndVector(CGPoint point, CGSize vector)
{
  return CGPointMake(point.x+vector.width, point.y+vector.height);  
}


CGSize addVectors(CGSize vector1, CGSize vector2)
{
  return CGSizeMake(vector1.width+vector2.width, vector1.height+vector2.height);  
}


CGSize vectorFromFirstToSecondPoint(CGPoint first, CGPoint second)
{
  return CGSizeMake(second.x-first.x, second.y-first.y);
}


CGSize vectorFromFirstToSecondVector(CGSize first, CGSize second)
{
  return CGSizeMake(second.width-first.width, second.height-first.height);
}



CGFloat distanceBetweenPoints(CGPoint first, CGPoint second)
{
  return lengthOfVector(vectorFromFirstToSecondPoint(first, second));
};


CGPoint movePointAlongVector(CGPoint point, CGSize vector, CGFloat factor, CGFloat orthogonalFactor)
{
  CGPoint p;
  p.x = point.x + factor*vector.width;
  p.y = point.y + factor*vector.height;
  if (orthogonalFactor) {
    // also move orthogonally to vector
    p.x = p.x + orthogonalFactor*-vector.height;
    p.y = p.y + orthogonalFactor*vector.width;
  }
  return p;
}



// normalize angle to be within +-pi
CGFloat normalizeAngle(CGFloat aAngle)
{
  while (aAngle<M_PI) aAngle += 2*M_PI;
  while (aAngle>M_PI) aAngle -= 2*M_PI;
  return aAngle;
}



CGSize scaleVector(CGSize vector, CGFloat factor)
{
  return CGSizeMake(vector.width*factor, vector.height*factor);
}


CGSize pointToSize(CGPoint point)
{
  return CGSizeMake(point.x, point.y);
}


CGPoint sizeToPoint(CGSize size)
{
  return CGPointMake(size.width, size.height);
}