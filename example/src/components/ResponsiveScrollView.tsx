import React from 'react';

import {
  KeyboardAvoidingView,
  ScrollView,
  Platform,
  ScrollViewProps,
} from 'react-native';

const ResponsiveScrollView = React.forwardRef(
  (props: ScrollViewProps, ref: React.ForwardedRef<ScrollView>) => (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      keyboardVerticalOffset={100}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        {...props}
        ref={ref}
        contentContainerStyle={{ paddingBottom: 60 }}
      >
        {props.children}
      </ScrollView>
    </KeyboardAvoidingView>
  )
);

export default ResponsiveScrollView;
