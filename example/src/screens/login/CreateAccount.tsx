import React from 'react';
import { BankReduxProps, connector } from '../../redux/connector';

import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { AuthStackParamList } from '.';

import ResponsiveScrollView from '../../components/ResponsiveScrollView';

import { Box, VStack, FormControl, Button, Input, Icon } from 'native-base';
import auth from '@react-native-firebase/auth';
import MaterialIcons from 'react-native-vector-icons/MaterialIcons';
import { passwordMinLen } from '../../config';

type CreateAccountProps = NativeStackScreenProps<
  AuthStackParamList,
  'CreateAccount'
> &
  BankReduxProps;

const CreateAccount: React.FC<CreateAccountProps> = (
  _props: CreateAccountProps
) => {
  const [loading, setLoading] = React.useState(false);
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [confirm, setConfirm] = React.useState('');
  const [errors, setErrors] = React.useState<{
    email?: string;
    password?: string;
    confirm?: string;
    create?: string;
  }>({});

  const validate = () => {
    const emailError = !email;
    const passwordError = password.length < passwordMinLen;
    const passwordMatchError = password !== confirm;
    setErrors({
      email: emailError ? 'username is required' : undefined,
      password: passwordError
        ? `Password minimum length is ${passwordMinLen}`
        : undefined,
      confirm: passwordMatchError ? 'Passwords do not match' : undefined,
    });
    return !emailError && !passwordError && !passwordMatchError;
  };

  async function handleCreate() {
    if (validate()) {
      try {
        setLoading(true);
        const credential = await auth().createUserWithEmailAndPassword(
          email,
          password
        );
        await credential.user.sendEmailVerification();
      } catch (e) {
        setLoading(false);
        setErrors({
          create: `${e}`,
        });
      }
    }
  }

  return (
    <ResponsiveScrollView>
      <Box flex={1} p="2" py="8" w="90%" mx="auto" alignItems="flex-start">
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
          <FormControl isRequired isInvalid={!!errors.confirm}>
            <FormControl.Label>Confirm Password</FormControl.Label>
            <Input
              type="password"
              autoComplete="password"
              value={confirm}
              onChangeText={(text: string) => {
                setConfirm(text);
              }}
            />
            <FormControl.ErrorMessage>
              {errors.confirm}
            </FormControl.ErrorMessage>
          </FormControl>
          <FormControl isRequired isInvalid={!!errors.create}>
            <FormControl.ErrorMessage>{errors.create}</FormControl.ErrorMessage>
            <Button
              isLoading={loading}
              mt="2"
              onPress={handleCreate}
              startIcon={<Icon as={MaterialIcons} name="add" />}
            >
              Create Account
            </Button>
          </FormControl>
        </VStack>
      </Box>
    </ResponsiveScrollView>
  );
};

export default connector(CreateAccount);
