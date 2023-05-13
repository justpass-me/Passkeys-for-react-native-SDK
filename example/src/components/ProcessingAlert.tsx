import React from 'react';

import { AlertDialog, Spinner, Text } from 'native-base';
import LottieView from 'lottie-react-native';
const successAnimation = require('../../assets/animations/1818-success-animation.json');

const ProgcessingAlert: React.FC<{
  isProcessing: boolean;
  isSuccessful: boolean;
  processingText: string;
  successText: string;
  onSuccess?: (isCanceled: boolean) => void;
}> = (props) => {
  const processingRef = React.useRef();

  return (
    <AlertDialog
      isOpen={props.isProcessing || props.isSuccessful}
      leastDestructiveRef={processingRef}
    >
      <AlertDialog.Content>
        <AlertDialog.Body py="10" alignItems="center" flex="1">
          <Text fontSize="lg" ref={processingRef}>
            {props.isSuccessful ? props.successText : props.processingText} ...
          </Text>
          {props.isSuccessful ? (
            <LottieView
              source={successAnimation}
              autoPlay
              loop={false}
              style={{ height: 100 }}
              onAnimationFinish={props.onSuccess}
            />
          ) : (
            <Spinner size="lg" />
          )}
        </AlertDialog.Body>
      </AlertDialog.Content>
    </AlertDialog>
  );
};

export default ProgcessingAlert;
