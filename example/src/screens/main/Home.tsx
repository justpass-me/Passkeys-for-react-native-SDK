import React from 'react';

import { Button, VStack, Heading, Stack } from 'native-base';

import ResponsiveScrollView from '../../components/ResponsiveScrollView';

import { MainDrawerParamsList, RootStackParamList } from '.';

import { connector, BankReduxProps } from '../../redux/connector';

import type { CompositeScreenProps } from '@react-navigation/native';
import type { DrawerScreenProps } from '@react-navigation/drawer';
import type { StackScreenProps } from '@react-navigation/stack';
import ProgcessingAlert from '../../components/ProcessingAlert';
import { register } from '@justpass-me/justpass-me-react-native';
import { REGISTER_URL } from '../../config';
import { Alert } from 'react-native';

type HomeProps = CompositeScreenProps<
  DrawerScreenProps<MainDrawerParamsList, 'Home'>,
  StackScreenProps<RootStackParamList>
> &
  BankReduxProps;

const Home: React.FC<HomeProps> = (props: HomeProps) => {
  const [isProcessing, setProcessing] = React.useState(false);
  const [isSuccessful, setSuccessful] = React.useState(false);

  if (!props.currentUser) {
    return <></>;
  }

  const definedUser = props.currentUser;
  console.log('userData', props.userData);

  return (
    <Stack
      direction={{ base: 'column', md: 'column', sm: 'column', lg: 'row' }}
      h="100%"
      flex={1}
    >
      <ResponsiveScrollView>
        <VStack mx="2">
          <Heading>
            Welcome {`${definedUser.displayName ?? definedUser.email}`}!
          </Heading>
          <Button
            mt="2"
            onPress={async () => {
              try {
                setProcessing(true);
                const idToken = await definedUser.getIdToken();
                const result = await register(REGISTER_URL, {
                  Authorization: `Bearer ${idToken}`,
                });
                console.log(result);
                setSuccessful(true);
              } catch (err: any) {
                console.log(err);
                if (
                  err.message !==
                  'The operation couldn’t be completed. (com.apple.AuthenticationServices.AuthorizationError error 1001.)'
                ) {
                  Alert.alert(err.message);
                }
              } finally {
                setProcessing(false);
              }
            }}
          >
            Register Biometrics
          </Button>
        </VStack>
        <ProgcessingAlert
          isProcessing={isProcessing}
          isSuccessful={isSuccessful}
          processingText={'Starting Registration'}
          successText={'Registration Successful'}
          onSuccess={() => setSuccessful(false)}
        />
      </ResponsiveScrollView>
    </Stack>
  );
};

export default connector(Home);
