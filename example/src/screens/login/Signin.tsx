import React from 'react';
import { BankReduxProps, connector } from '../../redux/connector';

import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { AuthStackParamList } from '.';

import ResponsiveScrollView from '../../components/ResponsiveScrollView';
import { authenticate } from '@justpass-me/justpass-me-react-native';

import {
  Box,
  Heading,
  VStack,
  FormControl,
  Button,
  Input,
  Icon,
  Link,
} from 'native-base';
import { passwordMinLen, AUTHENTICATE_URL } from '../../config';
import MaterialIcons from 'react-native-vector-icons/MaterialIcons';
import auth from '@react-native-firebase/auth';
import ProgcessingAlert from '../../components/ProcessingAlert';
import { Alert } from 'react-native';

type SignInProps = NativeStackScreenProps<AuthStackParamList, 'Signin'> &
  BankReduxProps;

const Signin: React.FC<SignInProps> = (props: SignInProps) => {
  const [isProcessing, setProcessing] = React.useState(false);
  const [isSuccessful, setSuccessful] = React.useState(false);
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [errors, setErrors] = React.useState<{
    email?: string;
    password?: string;
    login?: string;
  }>({});

  const validate = () => {
    const emailError = !email;
    const passwordError = password.length < passwordMinLen;
    setErrors({
      email: emailError ? 'email is required' : undefined,
      password: passwordError
        ? `Password minimum length is ${passwordMinLen}`
        : undefined,
    });

    return !emailError && !passwordError;
  };

  const onSubmit = async () => {
    if (validate()) {
      try {
        await auth().signInWithEmailAndPassword(email, password);
      } catch (err) {
        setErrors({
          login: `${err}`,
        });
      }
    }
  };

  return (
    <ResponsiveScrollView>
      <Box flex={1} p="2" py="8" w="90%" mx="auto" alignItems="flex-start">
        <Heading mt="1" size="xs">
          Welcome to <Link href="https:/www.justpass.me">justpass.me</Link>{' '}
          Firebase demo
        </Heading>

        <VStack space={3} mt="5" alignSelf="center" w="100%">
          <FormControl isRequired isInvalid={!!errors.email}>
            <FormControl.Label>Email</FormControl.Label>
            <Input
              type="text"
              autoComplete="email"
              autoCapitalize="none"
              value={email}
              onChangeText={(text: string) => {
                setEmail(text);
              }}
            />
            <FormControl.ErrorMessage>{errors.email}</FormControl.ErrorMessage>
          </FormControl>
          <FormControl isRequired isInvalid={!!errors.password}>
            <FormControl.Label>Password</FormControl.Label>
            <Input
              type="password"
              autoComplete="password"
              value={password}
              onChangeText={(text: string) => {
                setPassword(text);
              }}
            />
            <FormControl.ErrorMessage>
              {errors.password}
            </FormControl.ErrorMessage>
          </FormControl>
          <FormControl isRequired isInvalid={!!errors.login}>
            <FormControl.ErrorMessage>{errors.login}</FormControl.ErrorMessage>
            <Button
              mt="2"
              onPress={onSubmit}
              startIcon={<Icon as={MaterialIcons} name="lock" />}
            >
              Sign In
            </Button>
          </FormControl>
          <FormControl isRequired>
            <Button
              mt="2"
              onPress={async () => {
                try {
                  setProcessing(true);
                  const result = await authenticate(AUTHENTICATE_URL);
                  if (result.token) {
                    await auth().signInWithCustomToken(result.token);
                    setSuccessful(true);
                  }
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
              startIcon={<Icon as={MaterialIcons} name="fingerprint" />}
            >
              Passkey Login
            </Button>
          </FormControl>
          <FormControl isRequired isInvalid={!!errors.login}>
            <FormControl.ErrorMessage>{errors.login}</FormControl.ErrorMessage>
            <Button
              mt="2"
              variant="outline"
              onPress={() => {
                props.navigation.navigate('CreateAccount');
              }}
              startIcon={<Icon as={MaterialIcons} name="add" />}
            >
              Create An Account
            </Button>
          </FormControl>
        </VStack>
        <ProgcessingAlert
          isProcessing={isProcessing}
          isSuccessful={isSuccessful}
          processingText={'Starting Login'}
          successText={'Login Successful'}
          onSuccess={() => setSuccessful(false)}
        />
      </Box>
    </ResponsiveScrollView>
  );
};

export default connector(Signin);
