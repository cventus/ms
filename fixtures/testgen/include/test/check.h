struct check_test {
	int (*test)(void);
	char const *description;
};

int before_all(void);
int after_all(void);
int before_each(void);
int after_each(void);
